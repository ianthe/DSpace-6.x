/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.xmlworkflow;

import org.apache.commons.collections.CollectionUtils;
import org.apache.log4j.Logger;
import org.dspace.authorize.AuthorizeException;
import org.dspace.authorize.ResourcePolicy;
import org.dspace.authorize.service.AuthorizeService;
import org.dspace.content.*;
import org.dspace.content.Collection;
import org.dspace.content.service.InstallItemService;
import org.dspace.content.service.ItemService;
import org.dspace.content.service.WorkspaceItemService;
import org.dspace.core.*;
import org.dspace.eperson.EPerson;
import org.dspace.eperson.Group;
import org.dspace.eperson.service.GroupService;
import org.dspace.handle.service.HandleService;
import org.dspace.services.factory.DSpaceServicesFactory;
import org.dspace.usage.UsageWorkflowEvent;
import org.dspace.workflow.WorkflowException;
import org.dspace.xmlworkflow.factory.XmlWorkflowFactory;
import org.dspace.xmlworkflow.service.WorkflowRequirementsService;
import org.dspace.xmlworkflow.service.XmlWorkflowService;
import org.dspace.xmlworkflow.state.Step;
import org.dspace.xmlworkflow.state.Workflow;
import org.dspace.xmlworkflow.state.actions.*;
import org.dspace.xmlworkflow.storedcomponents.*;
import org.dspace.xmlworkflow.storedcomponents.service.*;
import org.springframework.beans.factory.annotation.Autowired;

import javax.mail.MessagingException;
import javax.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.sql.SQLException;
import java.util.*;

/**
 * When an item is submitted and is somewhere in a workflow, it has a row in the
 * WorkflowItem table pointing to it.
 *
 * Once the item has completed the workflow it will be archived
 *
 * @author Bram De Schouwer (bram.deschouwer at dot com)
 * @author Kevin Van de Velde (kevin at atmire dot com)
 * @author Ben Bosman (ben at atmire dot com)
 * @author Mark Diggory (markd at atmire dot com)
 */
public class XmlWorkflowServiceImpl implements XmlWorkflowService {

    /* support for 'no notification' */
    protected Map<UUID, Boolean> noEMail = new HashMap<>();

    private Logger log = Logger.getLogger(XmlWorkflowServiceImpl.class);

    @Autowired(required = true)
    protected AuthorizeService authorizeService;
    @Autowired(required = true)
    protected CollectionRoleService collectionRoleService;
    @Autowired(required = true)
    protected ClaimedTaskService claimedTaskService;
    @Autowired(required = true)
    protected HandleService handleService;
    @Autowired(required = true)
    protected InstallItemService installItemService;
    @Autowired(required = true)
    protected ItemService itemService;
    @Autowired(required = true)
    protected PoolTaskService poolTaskService;
    @Autowired(required = true)
    protected WorkflowItemRoleService workflowItemRoleService;
    @Autowired(required = true)
    protected WorkflowRequirementsService workflowRequirementsService;
    @Autowired(required = true)
    protected XmlWorkflowFactory xmlWorkflowFactory;
    @Autowired(required = true)
    protected WorkspaceItemService workspaceItemService;
    @Autowired(required = true)
    protected XmlWorkflowItemService xmlWorkflowItemService;
    @Autowired(required = true)
    protected GroupService groupService;

    protected XmlWorkflowServiceImpl()
    {

    }


    @Override
    public void deleteCollection(Context context, Collection collection) throws SQLException, IOException, AuthorizeException {
        xmlWorkflowItemService.deleteByCollection(context, collection);
        collectionRoleService.deleteByCollection(context, collection);
    }

    @Override
    public List<String> getEPersonDeleteConstraints(Context context, EPerson ePerson) throws SQLException {
        List<String> constraints = new ArrayList<String>();
        if(CollectionUtils.isNotEmpty(claimedTaskService.findByEperson(context, ePerson)))
        {
            constraints.add("cwf_claimtask");
        }
        if(CollectionUtils.isNotEmpty(poolTaskService.findByEPerson(context, ePerson)))
        {
            constraints.add("cwf_pooltask");
        }
        if(CollectionUtils.isNotEmpty(workflowItemRoleService.findByEPerson(context, ePerson)))
        {
            constraints.add("cwf_workflowitemrole");
        }
        return constraints;
    }

    @Override
    public Group getWorkflowRoleGroup(Context context, Collection collection, String roleName, Group roleGroup) throws SQLException, IOException, WorkflowException, AuthorizeException {
        try {
            Role role = WorkflowUtils.getCollectionAndRepositoryRoles(collection).get(roleName);
            if(role.getScope() == Role.Scope.COLLECTION || role.getScope() == Role.Scope.REPOSITORY){
                roleGroup = WorkflowUtils.getRoleGroup(context, collection, role);
                if(roleGroup == null){
                    authorizeService.authorizeAction(context, collection, Constants.WRITE);
                    roleGroup = groupService.create(context);
                    if(role.getScope() == Role.Scope.COLLECTION){
                        groupService.setName(roleGroup,
                                "COLLECTION_" + collection.getID().toString()
                                        + "_WORKFLOW_ROLE_" + roleName);
                    }else{
                        groupService.setName(roleGroup,  role.getName());
                    }
                    groupService.update(context, roleGroup);
                    authorizeService.addPolicy(context, collection, Constants.ADD, roleGroup);
                    if(role.getScope() == Role.Scope.COLLECTION){
                        WorkflowUtils.createCollectionWorkflowRole(context, collection, roleName, roleGroup);
                    }
               }
            }
            return roleGroup;
        } catch (WorkflowConfigurationException e) {
            throw new WorkflowException(e);
        }
    }

    @Override
    public List<String> getFlywayMigrationLocations() {
        return Collections.singletonList("classpath:org.dspace.storage.rdbms.xmlworkflow");
    }

    @Override
    public XmlWorkflowItem start(Context context, WorkspaceItem wsi) throws SQLException, AuthorizeException, IOException, WorkflowException {
        try {
            Item myitem = wsi.getItem();
            Collection collection = wsi.getCollection();
            Workflow wf = xmlWorkflowFactory.getWorkflow(collection);

            XmlWorkflowItem wfi = xmlWorkflowItemService.create(context, myitem, collection);
            wfi.setMultipleFiles(wsi.hasMultipleFiles());
            wfi.setMultipleTitles(wsi.hasMultipleTitles());
            wfi.setPublishedBefore(wsi.isPublishedBefore());
            xmlWorkflowItemService.update(context, wfi);
            removeUserItemPolicies(context, myitem, myitem.getSubmitter());
            grantSubmitterReadPolicies(context, myitem);

            context.turnOffAuthorisationSystem();
            Step firstStep = wf.getFirstStep();
            if(firstStep.isValidStep(context, wfi)){
                 activateFirstStep(context, wf, firstStep, wfi);
            } else {
                //Get our next step, if none is found, archive our item
                firstStep = wf.getNextStep(context, wfi, firstStep, ActionResult.OUTCOME_COMPLETE);
                if(firstStep == null){
                    archive(context, wfi);
                }else{
                    activateFirstStep(context, wf, firstStep, wfi);
                }

            }
            // remove the WorkspaceItem
            workspaceItemService.deleteWrapper(context, wsi);
            context.restoreAuthSystemState();
            return wfi;
        } catch (WorkflowConfigurationException e) {
            throw new WorkflowException(e);
        }
    }

    //TODO: this is currently not used in our notifications. Look at the code used by the original WorkflowManager
    /**
     * startWithoutNotify() starts the workflow normally, but disables
     * notifications (useful for large imports,) for the first workflow step -
     * subsequent notifications happen normally
     */
    @Override
    public XmlWorkflowItem startWithoutNotify(Context context, WorkspaceItem wsi)
            throws SQLException, AuthorizeException, IOException, WorkflowException {
        // make a hash table entry with item ID for no notify
        // notify code checks no notify hash for item id
        noEMail.put(wsi.getItem().getID(), Boolean.TRUE);

        return start(context, wsi);
    }

    @Override
    public void alertUsersOnTaskActivation(Context c, XmlWorkflowItem wfi, String emailTemplate, List<EPerson> epa, String ...arguments) throws IOException, SQLException, MessagingException {
        if (noEMail.containsKey(wfi.getItem().getID())) {
            // suppress email, and delete key
            noEMail.remove(wfi.getItem().getID());
        } else {
            Email mail = Email.getEmail(I18nUtil.getEmailFilename(c.getCurrentLocale(), emailTemplate));
            for (String argument : arguments) {
                mail.addArgument(argument);
            }
            for (EPerson anEpa : epa) {
                mail.addRecipient(anEpa.getEmail());
            }

            mail.send();
        }
    }

    protected void grantSubmitterReadPolicies(Context context, Item item) throws SQLException, AuthorizeException {
              //A list of policies the user has for this item
        List<Integer>  userHasPolicies = new ArrayList<Integer>();
        List<ResourcePolicy> itempols = authorizeService.getPolicies(context, item);
        EPerson submitter = item.getSubmitter();
        for (ResourcePolicy resourcePolicy : itempols) {
            if(submitter.equals(resourcePolicy.getEPerson())){
                //The user has already got this policy so add it to the list
                userHasPolicies.add(resourcePolicy.getAction());
            }
        }
        //Make sure we don't add duplicate policies
        if(!userHasPolicies.contains(Constants.READ))
            addPolicyToItem(context, item, Constants.READ, submitter, ResourcePolicy.TYPE_SUBMISSION);
    }


    protected void activateFirstStep(Context context, Workflow wf, Step firstStep, XmlWorkflowItem wfi) throws AuthorizeException, IOException, SQLException, WorkflowException, WorkflowConfigurationException{
        WorkflowActionConfig firstActionConfig = firstStep.getUserSelectionMethod();
        firstActionConfig.getProcessingAction().activate(context, wfi);
        log.info(LogManager.getHeader(context, "start_workflow", firstActionConfig.getProcessingAction() + " workflow_item_id="
                + wfi.getID() + "item_id=" + wfi.getItem().getID() + "collection_id="
                + wfi.getCollection().getID()));

        // record the start of the workflow w/provenance message
        recordStart(context, wfi.getItem(), firstActionConfig.getProcessingAction());

        //Fire an event !
        logWorkflowEvent(context, firstStep.getWorkflow().getID(),  null, null, wfi, null, firstStep, firstActionConfig);

        //If we don't have a UI activate it
        if(!firstActionConfig.requiresUI()){
            ActionResult outcome = firstActionConfig.getProcessingAction().execute(context, wfi, firstStep, null);
            processOutcome(context, null, wf, firstStep, firstActionConfig, outcome, wfi, true);
        }
    }

    /*
     * Executes an action and returns the next.
     */
    @Override
    public WorkflowActionConfig doState(Context c, EPerson user, HttpServletRequest request, int workflowItemId, Workflow workflow, WorkflowActionConfig currentActionConfig) throws SQLException, AuthorizeException, IOException, MessagingException, WorkflowException {
        try {
            XmlWorkflowItem wi = xmlWorkflowItemService.find(c, workflowItemId);
            Step currentStep = currentActionConfig.getStep();
            if(currentActionConfig.getProcessingAction().isAuthorized(c, request, wi)){
                ActionResult outcome = currentActionConfig.getProcessingAction().execute(c, wi, currentStep, request);
                return processOutcome(c, user, workflow, currentStep, currentActionConfig, outcome, wi, false);
            }else{
                throw new AuthorizeException("You are not allowed to to perform this task.");
            }
        } catch (WorkflowConfigurationException e) {
            log.error(LogManager.getHeader(c, "error while executing state", "workflow:  " + workflow.getID() + " action: " + currentActionConfig.getId() + " workflowItemId: " + workflowItemId), e);
            WorkflowUtils.sendAlert(request, e);
            throw new WorkflowException(e);
        }
    }

    @Override
    public WorkflowActionConfig processOutcome(Context c, EPerson user, Workflow workflow, Step currentStep, WorkflowActionConfig currentActionConfig, ActionResult currentOutcome, XmlWorkflowItem wfi, boolean enteredNewStep) throws IOException, AuthorizeException, SQLException, WorkflowException {
        if(currentOutcome.getType() == ActionResult.TYPE.TYPE_PAGE || currentOutcome.getType() == ActionResult.TYPE.TYPE_ERROR){
            //Our outcome is a page or an error, so return our current action
            c.restoreAuthSystemState();
            return currentActionConfig;
        }else
        if(currentOutcome.getType() == ActionResult.TYPE.TYPE_CANCEL || currentOutcome.getType() == ActionResult.TYPE.TYPE_SUBMISSION_PAGE){
            //We either pressed the cancel button or got an order to return to the submission page, so don't return an action
            //By not returning an action we ensure ourselfs that we go back to the submission page
            c.restoreAuthSystemState();
            return null;
        }else
        if (currentOutcome.getType() == ActionResult.TYPE.TYPE_OUTCOME) {
            Step nextStep = null;
            WorkflowActionConfig nextActionConfig = null;
            try {
                //We have completed our action search & retrieve the next action
                if(currentOutcome.getResult() == ActionResult.OUTCOME_COMPLETE){
                    nextActionConfig = currentStep.getNextAction(currentActionConfig);
                }

                if (nextActionConfig != null) {
                    //We remain in the current step since an action is found
                    nextStep = currentStep;
                    nextActionConfig.getProcessingAction().activate(c, wfi);
                    if (nextActionConfig.requiresUI() && !enteredNewStep) {
                        createOwnedTask(c, wfi, currentStep, nextActionConfig, user);
                        return nextActionConfig;
                    } else if( nextActionConfig.requiresUI() && enteredNewStep){
                        //We have entered a new step and have encountered a UI, return null since the current user doesn't have anything to do with this
                        c.restoreAuthSystemState();
                        return null;
                    } else {
                        ActionResult newOutcome = nextActionConfig.getProcessingAction().execute(c, wfi, currentStep, null);
                        return processOutcome(c, user, workflow, currentStep, nextActionConfig, newOutcome, wfi, enteredNewStep);
                    }
                }else
                if(enteredNewStep){
                    // If the user finished his/her step, we keep processing until there is a UI step action or no step at all
                    nextStep = workflow.getNextStep(c, wfi, currentStep, currentOutcome.getResult());
                    c.turnOffAuthorisationSystem();
                    nextActionConfig = processNextStep(c, user, workflow, currentOutcome, wfi, nextStep);
                    //If we require a user interface return null so that the user is redirected to the "submissions page"
                    if(nextActionConfig == null || nextActionConfig.requiresUI()){
                        return null;
                    }else{
                        return nextActionConfig;
                    }
                } else {
                    ClaimedTask task = claimedTaskService.findByWorkflowIdAndEPerson(c, wfi, user);

                    //Check if we have a task for this action (might not be the case with automatic steps)
                    //First add it to our list of finished users, since no more actions remain
                    workflowRequirementsService.addFinishedUser(c, wfi, user);
                    c.turnOffAuthorisationSystem();
                    //Check if our requirements have been met
                    if((currentStep.isFinished(c, wfi) && currentOutcome.getResult() == ActionResult.OUTCOME_COMPLETE) || currentOutcome.getResult() != ActionResult.OUTCOME_COMPLETE){
                        //Delete all the table rows containing the users who performed this task
                        workflowRequirementsService.clearInProgressUsers(c, wfi);
                        //Remove all the tasks
                        deleteAllTasks(c, wfi);


                        nextStep = workflow.getNextStep(c, wfi, currentStep, currentOutcome.getResult());

                        nextActionConfig = processNextStep(c, user, workflow, currentOutcome, wfi, nextStep);
                        //If we require a user interface return null so that the user is redirected to the "submissions page"
                        if(nextActionConfig == null || nextActionConfig.requiresUI()){
                            return null;
                        }else{
                            return nextActionConfig;
                        }
                    }else{
                        //We are done with our actions so go to the submissions page but remove action ClaimedAction first
                        deleteClaimedTask(c, wfi, task);
                        c.restoreAuthSystemState();
                        nextStep = currentStep;
                        nextActionConfig = currentActionConfig;
                        return null;
                    }
                }
            }catch (Exception e){
                log.error("error while processing workflow outcome", e);
                e.printStackTrace();
            }
            finally {
                if((nextStep != null && currentStep != null && nextActionConfig != null) || (wfi.getItem().isArchived() && currentStep != null)){
                    logWorkflowEvent(c, currentStep.getWorkflow().getID(), currentStep.getId(), currentActionConfig.getId(), wfi, user, nextStep, nextActionConfig);
                }
            }

        }

        log.error(LogManager.getHeader(c, "Invalid step outcome", "Workflow item id: " + wfi.getID()));
        throw new WorkflowException("Invalid step outcome");
    }

    protected void logWorkflowEvent(Context c, String workflowId, String previousStepId, String previousActionConfigId, XmlWorkflowItem wfi, EPerson actor, Step newStep, WorkflowActionConfig newActionConfig) throws SQLException {
        try {
            //Fire an event so we can log our action !
            Item item = wfi.getItem();
            Collection myCollection = wfi.getCollection();
            String workflowStepString = null;

            List<EPerson> currentEpersonOwners = new ArrayList<EPerson>();
            List<Group> currentGroupOwners = new ArrayList<Group>();
            //These are only null if our item is sent back to the submission
            if(newStep != null && newActionConfig != null){
                workflowStepString = workflowId + "." + newStep.getId() + "." + newActionConfig.getId();

                //Retrieve the current owners of the task
                List<ClaimedTask> claimedTasks = claimedTaskService.find(c, wfi, newStep.getId());
                List<PoolTask> pooledTasks = poolTaskService.find(c, wfi);
                for (PoolTask poolTask : pooledTasks){
                    if(poolTask.getEperson() != null){
                        currentEpersonOwners.add(poolTask.getEperson());
                    }else{
                        currentGroupOwners.add(poolTask.getGroup());
                    }
                }
                for (ClaimedTask claimedTask : claimedTasks) {
                    currentEpersonOwners.add(claimedTask.getOwner());
                }
            }
            String previousWorkflowStepString = null;
            if(previousStepId != null && previousActionConfigId != null){
                previousWorkflowStepString = workflowId + "." + previousStepId + "." + previousActionConfigId;
            }

            //Fire our usage event !
            UsageWorkflowEvent usageWorkflowEvent = new UsageWorkflowEvent(c, item, wfi, workflowStepString, previousWorkflowStepString, myCollection, actor);

            usageWorkflowEvent.setEpersonOwners(currentEpersonOwners.toArray(new EPerson[currentEpersonOwners.size()]));
            usageWorkflowEvent.setGroupOwners(currentGroupOwners.toArray(new Group[currentGroupOwners.size()]));

            DSpaceServicesFactory.getInstance().getEventService().fireEvent(usageWorkflowEvent);
        } catch (Exception e) {
            //Catch all errors we do not want our workflow to crash because the logging threw an exception
            log.error(LogManager.getHeader(c, "Error while logging workflow event", "Workflow Item: " + wfi.getID()), e);
        }
    }

    protected WorkflowActionConfig processNextStep(Context c, EPerson user, Workflow workflow, ActionResult currentOutcome, XmlWorkflowItem wfi, Step nextStep) throws SQLException, IOException, AuthorizeException, WorkflowException, WorkflowConfigurationException {
        WorkflowActionConfig nextActionConfig;
        if(nextStep!=null){
            nextActionConfig = nextStep.getUserSelectionMethod();
            nextActionConfig.getProcessingAction().activate(c, wfi);
//                nextActionConfig.getProcessingAction().generateTasks();

            if (nextActionConfig.requiresUI()) {
                //Since a new step has been started, stop executing actions once one with a user interface is present.
                c.restoreAuthSystemState();
                return nextActionConfig;
            } else {
                ActionResult newOutcome = nextActionConfig.getProcessingAction().execute(c, wfi, nextStep, null);
                c.restoreAuthSystemState();
                return processOutcome(c, user, workflow, nextStep, nextActionConfig, newOutcome, wfi, true);
            }
        }else{
            if(currentOutcome.getResult() != ActionResult.OUTCOME_COMPLETE){
                c.restoreAuthSystemState();
                throw new WorkflowException("No alternate step was found for outcome: " + currentOutcome.getResult());
            }
            archive(c, wfi);
            c.restoreAuthSystemState();
            return null;
        }
    }


    /**
     * Commit the contained item to the main archive. The item is associated
     * with the relevant collection, added to the search index, and any other
     * tasks such as assigning dates are performed.
     *
     * @return the fully archived item.
     */
    protected Item archive(Context context, XmlWorkflowItem wfi)
            throws SQLException, IOException, AuthorizeException {
        // FIXME: Check auth
        Item item = wfi.getItem();
        Collection collection = wfi.getCollection();

        // Remove (if any) the workflowItemroles for this item
        workflowItemRoleService.deleteForWorkflowItem(context, wfi);

        log.info(LogManager.getHeader(context, "archive_item", "workflow_item_id="
                + wfi.getID() + "item_id=" + item.getID() + "collection_id="
                + collection.getID()));

        installItemService.installItem(context, wfi);

        //Notify
        notifyOfArchive(context, item, collection);

        //Clear any remaining workflow metadata
        itemService.clearMetadata(context, item, WorkflowRequirementsService.WORKFLOW_SCHEMA, Item.ANY, Item.ANY, Item.ANY);
        itemService.update(context, item);

        // Log the event
        log.info(LogManager.getHeader(context, "install_item", "workflow_item_id="
                + wfi.getID() + ", item_id=" + item.getID() + "handle=FIXME"));

        return item;
    }

    /**
     * notify the submitter that the item is archived
     */
    protected void notifyOfArchive(Context context, Item item, Collection coll)
            throws SQLException, IOException {
        try {
            // Get submitter
            EPerson ep = item.getSubmitter();
            // Get the Locale
            Locale supportedLocale = I18nUtil.getEPersonLocale(ep);
            // Blank email
            Email email;

            if(coll.getName().equals("Library Theses"))
            {
                email = Email.getEmail(I18nUtil.getEmailFilename(supportedLocale, "etheses_complete"));
            }
            else
            {
                email = Email.getEmail(I18nUtil.getEmailFilename(supportedLocale, "submit_archive"));
            }

            // Get the item handle to email to user
            String handle = handleService.findHandle(context, item);

            // Get title
            List<MetadataValue> titles = itemService.getMetadata(item, MetadataSchema.DC_SCHEMA, "title", null, Item.ANY);
            String title = "";
            try {
                title = I18nUtil.getMessage("org.dspace.workflow.WorkflowManager.untitled");
            }
            catch (MissingResourceException e) {
                title = "Untitled";
            }
            if (titles.size() > 0) {
                title = titles.iterator().next().getValue();
            }

            email.addRecipient(ep.getEmail());

            if(coll.getName().equals("Library Theses"))
            {
                email.addArgument(ep.getFullName());
                email.addArgument(ep.getStudentId());
                email.addArgument(title);
                email.addArgument(handleService.getCanonicalForm(handle));
                email.addRecipientCC("registry-pgr@st-andrews.ac.uk");
                email.addRecipientCC("research-data@st-andrews.ac.uk");
                email.addRecipientCC("digirep@st-andrews.ac.uk");
            }
            else{
                
                email.addArgument(title);
                email.addArgument(coll.getName());
                email.addArgument(handleService.getCanonicalForm(handle));
            }

            email.send();
        }
        catch (MessagingException e) {
            log.warn(LogManager.getHeader(context, "notifyOfArchive",
                    "cannot email user" + " item_id=" + item.getID()));
        }
    }

    /***********************************
     * WORKFLOW TASK MANAGEMENT
     **********************************/
    /**
     * Deletes all tasks from this workflowflowitem
     * @param context the dspace context
     * @param wi the workflow item for whom we are to delete the tasks
     * @throws SQLException ...
     * @throws org.dspace.authorize.AuthorizeException ...
     */
    @Override
    public void deleteAllTasks(Context context, XmlWorkflowItem wi) throws SQLException, AuthorizeException {
        deleteAllPooledTasks(context, wi);

        Iterator<ClaimedTask> allClaimedTasks = claimedTaskService.findByWorkflowItem(context,wi).iterator();
        while (allClaimedTasks.hasNext()) {
            ClaimedTask task = allClaimedTasks.next();
            allClaimedTasks.remove();
            deleteClaimedTask(context, wi, task);
        }
    }

    @Override
    public void deleteAllPooledTasks(Context context, XmlWorkflowItem wi) throws SQLException, AuthorizeException {
        Iterator<PoolTask> allPooledTasks = poolTaskService.find(context, wi).iterator();
        while (allPooledTasks.hasNext()) {
            PoolTask poolTask = allPooledTasks.next();
            allPooledTasks.remove();
            deletePooledTask(context, wi, poolTask);
        }
    }

    /*
     * Deletes an eperson from the taskpool of a step
     */
    @Override
    public void deletePooledTask(Context context, XmlWorkflowItem wi, PoolTask task) throws SQLException, AuthorizeException {
        if(task != null){
            if(task.getEperson() != null){
                removeUserItemPolicies(context, wi.getItem(), task.getEperson());
            }else{
                removeGroupItemPolicies(context, wi.getItem(), task.getGroup());
            }
            poolTaskService.delete(context, task);
        }
    }

    @Override
    public void deleteClaimedTask(Context c, XmlWorkflowItem wi, ClaimedTask task) throws SQLException, AuthorizeException {
        if(task != null){
            removeUserItemPolicies(c, wi.getItem(), task.getOwner());
            claimedTaskService.delete(c, task);
        }
    }

    /*
     * Creates a task pool for a given step
     */
    @Override
    public void createPoolTasks(Context context, XmlWorkflowItem wi, RoleMembers assignees, Step step, WorkflowActionConfig action)
            throws SQLException, AuthorizeException {
        // create a tasklist entry for each eperson
        for (EPerson anEpa : assignees.getEPersons()) {
            PoolTask task = poolTaskService.create(context);
            task.setStepID(step.getId());
            task.setWorkflowID(step.getWorkflow().getID());
            task.setEperson(anEpa);
            task.setActionID(action.getId());
            task.setWorkflowItem(wi);
            poolTaskService.update(context, task);
            //Make sure this user has a task
            grantUserAllItemPolicies(context, wi.getItem(), anEpa);
        }
        for(Group group: assignees.getGroups()){
            PoolTask task = poolTaskService.create(context);
            task.setStepID(step.getId());
            task.setWorkflowID(step.getWorkflow().getID());
            task.setGroup(group);
            task.setActionID(action.getId());
            task.setWorkflowItem(wi);
            poolTaskService.update(context, task);
            //Make sure this user has a task
            grantGroupAllItemPolicies(context, wi.getItem(), group);
        }
    }

    /*
     * Claims an action for a given eperson
     */
    @Override
    public void createOwnedTask(Context context, XmlWorkflowItem wi, Step step, WorkflowActionConfig action, EPerson e) throws SQLException, AuthorizeException {
        ClaimedTask task = claimedTaskService.create(context);
        task.setWorkflowItem(wi);
        task.setStepID(step.getId());
        task.setActionID(action.getId());
        task.setOwner(e);
        task.setWorkflowID(step.getWorkflow().getID());
        claimedTaskService.update(context, task);
        //Make sure this user has a task
        grantUserAllItemPolicies(context, wi.getItem(), e);
    }

    public void grantUserAllItemPolicies(Context context, Item item, EPerson epa) throws AuthorizeException, SQLException {
        if (epa != null){
            //A list of policies the user has for this item
            List<Integer>  userHasPolicies = new ArrayList<Integer>();
            List<ResourcePolicy> itempols = authorizeService.getPolicies(context, item);
            for (ResourcePolicy resourcePolicy : itempols) {
                if(epa.equals(resourcePolicy.getEPerson())){
                    //The user has already got this policy so it it to the list
                    userHasPolicies.add(resourcePolicy.getAction());
                }
            }

            //Make sure we don't add duplicate policies
            if(!userHasPolicies.contains(Constants.READ))
                addPolicyToItem(context, item, Constants.READ, epa);
            if(!userHasPolicies.contains(Constants.WRITE))
                addPolicyToItem(context, item, Constants.WRITE, epa);
            if(!userHasPolicies.contains(Constants.DELETE))
                addPolicyToItem(context, item, Constants.DELETE, epa);
            if(!userHasPolicies.contains(Constants.ADD))
                addPolicyToItem(context, item, Constants.ADD, epa);
            if(!userHasPolicies.contains(Constants.REMOVE))
                addPolicyToItem(context, item, Constants.REMOVE, epa);
        }
    }

    protected void grantGroupAllItemPolicies(Context context, Item item, Group group) throws AuthorizeException, SQLException {
        if(group != null){
            //A list of policies the user has for this item
            List<Integer>  groupHasPolicies = new ArrayList<Integer>();
            List<ResourcePolicy> itempols = authorizeService.getPolicies(context, item);
            for (ResourcePolicy resourcePolicy : itempols) {
                if(group.equals(resourcePolicy.getGroup())){
                    //The user has already got this policy so it it to the list
                    groupHasPolicies.add(resourcePolicy.getAction());
                }
            }
            //Make sure we don't add duplicate policies
            if(!groupHasPolicies.contains(Constants.READ))
                addGroupPolicyToItem(context, item, Constants.READ, group);
            if(!groupHasPolicies.contains(Constants.WRITE))
                addGroupPolicyToItem(context, item, Constants.WRITE, group);
            if(!groupHasPolicies.contains(Constants.DELETE))
                addGroupPolicyToItem(context, item, Constants.DELETE, group);
            if(!groupHasPolicies.contains(Constants.ADD))
                addGroupPolicyToItem(context, item, Constants.ADD, group);
            if(!groupHasPolicies.contains(Constants.REMOVE))
                addGroupPolicyToItem(context, item, Constants.REMOVE, group);
        }
    }

    protected void addPolicyToItem(Context context, Item item, int type, EPerson epa) throws AuthorizeException, SQLException {
        addPolicyToItem(context, item, type, epa, null);
    }

    protected void addPolicyToItem(Context context, Item item, int type, EPerson epa, String policyType) throws AuthorizeException, SQLException {
        if(epa != null){
            authorizeService.addPolicy(context, item, type, epa, policyType);
            List<Bundle> bundles = item.getBundles();
            for (Bundle bundle : bundles) {
                authorizeService.addPolicy(context, bundle, type, epa, policyType);
                List<Bitstream> bits = bundle.getBitstreams();
                for (Bitstream bit : bits) {
                    authorizeService.addPolicy(context, bit, type, epa, policyType);
                }
            }
        }
    }

    protected void addGroupPolicyToItem(Context context, Item item, int type, Group group) throws AuthorizeException, SQLException {
        if(group != null){
            authorizeService.addPolicy(context, item, type, group);
            List<Bundle> bundles = item.getBundles();
            for (Bundle bundle : bundles) {
                authorizeService.addPolicy(context, bundle, type, group);
                List<Bitstream> bits = bundle.getBitstreams();
                for (Bitstream bit : bits) {
                    authorizeService.addPolicy(context, bit, type, group);
                }
            }
        }
    }

    public void removeUserItemPolicies(Context context, Item item, EPerson e) throws SQLException, AuthorizeException {
        if (e != null){
            //Also remove any lingering authorizations from this user
            authorizeService.removeEPersonPolicies(context, item, e);
            //Remove the bundle rights
            List<Bundle> bundles = item.getBundles();
            for (Bundle bundle : bundles) {
                authorizeService.removeEPersonPolicies(context, bundle, e);
                List<Bitstream> bitstreams = bundle.getBitstreams();
                for (Bitstream bitstream : bitstreams) {
                    authorizeService.removeEPersonPolicies(context, bitstream, e);
                }
            }
            // Ensure that the submitter always retains his resource policies
            if(e.getID().equals(item.getSubmitter().getID())){
                grantSubmitterReadPolicies(context, item);
            }
        }
    }


    protected void removeGroupItemPolicies(Context context, Item item, Group e) throws SQLException, AuthorizeException {
        if(e != null){
            //Also remove any lingering authorizations from this user
            authorizeService.removeGroupPolicies(context, item, e);
            //Remove the bundle rights
            List<Bundle> bundles = item.getBundles();
            for (Bundle bundle : bundles) {
                authorizeService.removeGroupPolicies(context, bundle, e);
                List<Bitstream> bitstreams = bundle.getBitstreams();
                for (Bitstream bitstream : bitstreams) {
                    authorizeService.removeGroupPolicies(context, bitstream, e);
                }
            }
        }
    }

    @Override
    public WorkspaceItem sendWorkflowItemBackSubmission(Context context, XmlWorkflowItem wi, EPerson e, String provenance,
            String rejection_message) throws SQLException, AuthorizeException,
            IOException
    {

        String workflowID = null;
        String currentStepId = null;
        String currentActionConfigId = null;
        ClaimedTask claimedTask = claimedTaskService.findByWorkflowIdAndEPerson(context, wi, e);
        if(claimedTask != null){
            //Log it
            workflowID = claimedTask.getWorkflowID();
            currentStepId = claimedTask.getStepID();
            currentActionConfigId = claimedTask.getActionID();
        }
        context.turnOffAuthorisationSystem();

        // rejection provenance
        Item myitem = wi.getItem();

        // Get current date
        String now = DCDate.getCurrent().toString();

        // Get user's name + email address
        String usersName = getEPersonName(e);

        // Here's what happened
        String provDescription = provenance + " Rejected by " + usersName + ", reason: "
                + rejection_message + " on " + now + " (GMT) ";

        // Add to item as a DC field
        itemService.addMetadata(context, myitem, MetadataSchema.DC_SCHEMA, "description", "provenance", "en", provDescription);

        //Clear any workflow schema related metadata
        itemService.clearMetadata(context, myitem, WorkflowRequirementsService.WORKFLOW_SCHEMA, Item.ANY, Item.ANY, Item.ANY);

        itemService.update(context, myitem);

        // convert into personal workspace
        WorkspaceItem wsi = returnToWorkspace(context, wi);

        // notify that it's been rejected
        notifyOfReject(context, wi, e, rejection_message);
        log.info(LogManager.getHeader(context, "reject_workflow", "workflow_item_id="
                + wi.getID() + "item_id=" + wi.getItem().getID()
                + "collection_id=" + wi.getCollection().getID() + "eperson_id="
                + e.getID()));

        logWorkflowEvent(context, workflowID, currentStepId, currentActionConfigId, wi, e, null, null);

        context.restoreAuthSystemState();
        return wsi;
    }

    @Override
    public WorkspaceItem abort(Context c, XmlWorkflowItem wi, EPerson e) throws AuthorizeException, SQLException, IOException {
        if (!authorizeService.isAdmin(c))
        {
            throw new AuthorizeException(
                    "You must be an admin to abort a workflow");
        }

        c.turnOffAuthorisationSystem();
        //Restore permissions for the submitter
        // convert into personal workspace
        WorkspaceItem wsi = returnToWorkspace(c, wi);

        log.info(LogManager.getHeader(c, "abort_workflow", "workflow_item_id="
                + wi.getID() + "item_id=" + wsi.getItem().getID()
                + "collection_id=" + wi.getCollection().getID() + "eperson_id="
                + e.getID()));


        c.restoreAuthSystemState();
        return wsi;
    }

    /**
     * Return the workflow item to the workspace of the submitter. The workflow
     * item is removed, and a workspace item created.
     *
     * @param c
     *            Context
     * @param wfi
     *            WorkflowItem to be 'dismantled'
     * @return the workspace item
     * @throws java.io.IOException ...
     * @throws java.sql.SQLException ...
     * @throws org.dspace.authorize.AuthorizeException ...
     */
    protected WorkspaceItem returnToWorkspace(Context c, XmlWorkflowItem wfi)
            throws SQLException, IOException, AuthorizeException
    {
                // authorize a DSpaceActions.REJECT
        // stop workflow
        deleteAllTasks(c, wfi);

        c.turnOffAuthorisationSystem();
        //Also clear all info for this step
        workflowRequirementsService.clearInProgressUsers(c, wfi);

        // Remove (if any) the workflowItemroles for this item
        workflowItemRoleService.deleteForWorkflowItem(c, wfi);

        Item myitem = wfi.getItem();
        //Restore permissions for the submitter
        grantUserAllItemPolicies(c, myitem, myitem.getSubmitter());

        // FIXME: How should this interact with the workflow system?
        // FIXME: Remove license
        // FIXME: Provenance statement?
        // Create the new workspace item row
        WorkspaceItem workspaceItem = workspaceItemService.create(c, wfi);
        workspaceItem.setMultipleFiles(wfi.hasMultipleFiles());
        workspaceItem.setMultipleTitles(wfi.hasMultipleTitles());
        workspaceItem.setPublishedBefore(wfi.isPublishedBefore());
        workspaceItemService.update(c, workspaceItem);

        //myitem.update();
        log.info(LogManager.getHeader(c, "return_to_workspace",
                "workflow_item_id=" + wfi.getID() + "workspace_item_id="
                        + workspaceItem.getID()));

        // Now remove the workflow object manually from the database
        xmlWorkflowItemService.deleteWrapper(c, wfi);
        return workspaceItem;
    }

    @Override
    public String getEPersonName(EPerson ePerson)
    {
        String submitter = ePerson.getFullName();

        submitter = submitter + "(" + ePerson.getEmail() + ")";

        return submitter;
    }

    // Create workflow start provenance message
    protected void recordStart(Context context, Item myitem, Action action)
            throws SQLException, IOException, AuthorizeException
    {
        // get date
        DCDate now = DCDate.getCurrent();

        // Create provenance description
        String provmessage = "";

        if (myitem.getSubmitter() != null)
        {
            provmessage = "Submitted by " + myitem.getSubmitter().getFullName()
                    + " (" + myitem.getSubmitter().getEmail() + ") on "
                    + now.toString() + " workflow start=" + action.getProvenanceStartId() + "\n";
        }
        else
        // null submitter
        {
            provmessage = "Submitted by unknown (probably automated) on"
                    + now.toString() + " workflow start=" + action.getProvenanceStartId() + "\n";
        }

        // add sizes and checksums of bitstreams
        provmessage += installItemService.getBitstreamProvenanceMessage(context, myitem);

        // Add message to the DC
        itemService.addMetadata(context, myitem, MetadataSchema.DC_SCHEMA, "description", "provenance", "en", provmessage);
        itemService.update(context, myitem);
    }

    protected void notifyOfReject(Context c, XmlWorkflowItem wi, EPerson e,
        String reason)
    {
        try
        {
            // Get the item title
            String title = wi.getItem().getName();

            // Get the collection
            Collection coll = wi.getCollection();

            // Get rejector's name
            String rejector = getEPersonName(e);
            Locale supportedLocale = I18nUtil.getEPersonLocale(e);
            Email email = Email.getEmail(I18nUtil.getEmailFilename(supportedLocale,"submit_reject"));

            email.addRecipient(wi.getSubmitter().getEmail());
            email.addArgument(title);
            email.addArgument(coll.getName());
            email.addArgument(rejector);
            email.addArgument(reason);
            email.addArgument(ConfigurationManager.getProperty("dspace.url") + "/mydspace");

            email.send();
        }
        catch (Exception ex)
        {
            // log this email error
            log.warn(LogManager.getHeader(c, "notify_of_reject",
                    "cannot email user" + " eperson_id" + e.getID()
                            + " eperson_email" + e.getEmail()
                            + " workflow_item_id" + wi.getID()));
        }
    }

    @Override
    public String getMyDSpaceLink() {
        return ConfigurationManager.getProperty("dspace.url") + "/mydspace";
    }
}
