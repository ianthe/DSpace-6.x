<!--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

-->

<!--
    Rendering specific to the item display page.

    Author: art.lowel at atmire.com
    Author: lieven.droogmans at atmire.com
    Author: ben at atmire.com
    Author: Alexey Maslov

-->

<xsl:stylesheet
    xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
    xmlns:dri="http://di.tamu.edu/DRI/1.0/"
    xmlns:mets="http://www.loc.gov/METS/"
    xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"
    xmlns:xlink="http://www.w3.org/TR/xlink/"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:atom="http://www.w3.org/2005/Atom"
    xmlns:ore="http://www.openarchives.org/ore/terms/"
    xmlns:oreatom="http://www.openarchives.org/ore/atom/"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xalan="http://xml.apache.org/xalan"
    xmlns:encoder="xalan://java.net.URLEncoder"
    xmlns:util="org.dspace.app.xmlui.utils.XSLUtils"
    xmlns:jstring="java.lang.String"
    xmlns:rights="http://cosimo.stanford.edu/sdr/metsrights/"
    xmlns:confman="org.dspace.core.ConfigurationManager"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:cc="http://creativecommons.org/ns#"
    xmlns:sxl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="xalan encoder i18n dri mets dim xlink xsl util jstring rights confman">

    <xsl:output indent="yes"/>

    <xsl:template name="itemSummaryView-DIM">
        <!-- Generate the info about the item from the metadata section -->
        <xsl:apply-templates select="./mets:dmdSec/mets:mdWrap[@OTHERMDTYPE='DIM']/mets:xmlData/dim:dim" mode="itemSummaryView-DIM"/>

        <xsl:copy-of select="$SFXLink" />

        <!--<xsl:if test="./mets:fileSec/mets:fileGrp[@USE='CC-LICENSE']/mets:file/mets:FLocat[@xlink:title='license_text']">
            <div class="license-info table">
                <ul class="list-unstyled">
                    <xsl:apply-templates select="./mets:fileSec/mets:fileGrp[@USE='CC-LICENSE']" mode="simple"/>
                </ul>
            </div>
        </xsl:if>-->


    </xsl:template>

    <!-- An item rendered in the detailView pattern, the "full item record" view of a DSpace item in Manakin. -->
    <xsl:template name="itemDetailView-DIM">

        <!--<xsl:call-template name="itemSummaryView-DIM-title"/>-->

        <!-- Generate the bitstream information from the file section -->
        <xsl:choose>
            <!--<xsl:when test="./mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL' or @USE='LICENSE']/mets:file">-->
            <xsl:when test="./mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL']/mets:file">
                <h3 class="file-heading"><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-head</i18n:text></h3>
                <div class="file-list">
                    <!--<xsl:apply-templates select="./mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL' or @USE='LICENSE' or @USE='CC-LICENSE']">-->
                    <xsl:apply-templates select="./mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL']">
                        <xsl:with-param name="context" select="."/>
                        <xsl:with-param name="primaryBitstream" select="./mets:structMap[@TYPE='LOGICAL']/mets:div[@TYPE='DSpace Item']/mets:fptr/@FILEID"/>
                    </xsl:apply-templates>
                </div>
            </xsl:when>
            <!-- Special case for handling ORE resource maps stored as DSpace bitstreams -->
            <xsl:when test="./mets:fileSec/mets:fileGrp[@USE='ORE']">
                <xsl:apply-templates select="./mets:fileSec/mets:fileGrp[@USE='ORE']" mode="itemDetailView-DIM" />
            </xsl:when>
            <xsl:otherwise>
                <h2><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-head</i18n:text></h2>
                <table class="ds-table file-list">
                    <tr class="ds-table-header-row">
                        <th><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-file</i18n:text></th>
                        <th><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-size</i18n:text></th>
                        <th><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-format</i18n:text></th>
                        <th><i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-view</i18n:text></th>
                    </tr>
                    <tr>
                        <td colspan="4">
                            <p><i18n:text>xmlui.dri2xhtml.METS-1.0.item-no-files</i18n:text></p>
                        </td>
                    </tr>
                </table>
            </xsl:otherwise>
        </xsl:choose>

        <!-- Output all of the metadata about the item from the metadata section -->
        <xsl:apply-templates select="mets:dmdSec/mets:mdWrap[@OTHERMDTYPE='DIM']/mets:xmlData/dim:dim"
                             mode="itemDetailView-DIM"/>

        <!-- Generate the Creative Commons license information from the file section (DSpace deposit license hidden by default)-->
        <!--xsl:if test="./mets:fileSec/mets:fileGrp[@USE='LICENSE']/mets:file/mets:FLocat[@xlink:title='license.txt']"-->
        <xsl:if test="./mets:fileSec/mets:fileGrp[@USE='CC-LICENSE' or @USE='LICENSE']">
            <div class="license-info table">
                <p>
                    <i18n:text>xmlui.dri2xhtml.METS-1.0.license-text</i18n:text>
                </p>
                <ul class="list-unstyled">
                    <xsl:if test="./mets:fileSec/mets:fileGrp[@USE='LICENSE']/mets:file/mets:FLocat[@xlink:title='license.txt']">
                        <xsl:apply-templates select="./mets:fileSec/mets:fileGrp[@USE='LICENSE']" mode="simple"/>
                    </xsl:if>
                    <xsl:if test="./mets:fileSec/mets:fileGrp[@USE='CC-LICENSE']/mets:file/mets:FLocat[@xlink:title='license_text']">
                        <xsl:apply-templates select="./mets:fileSec/mets:fileGrp[@USE='CC-LICENSE']" mode="simple"/>
                    </xsl:if>
                </ul>
            </div>
        </xsl:if>

    </xsl:template>


    <xsl:template match="dim:dim" mode="itemSummaryView-DIM">
        <div class="item-summary-view-metadata">
            <xsl:call-template name="itemSummaryView-DIM-title"/>
            <div class="row">
                <div class="col-sm-4">
                    <div class="row">
                        <xsl:if test="/mets:METS/mets:fileSec/mets:fileGrp[@USE='THUMBNAIL']/mets:file[@GROUPID=../../mets:fileGrp[@USE='CONTENT']/mets:file[@GROUPID=../../mets:fileGrp[@USE='THUMBNAIL']/mets:file/@GROUPID][1]/@GROUPID]">
                            <xsl:call-template name="itemSummaryView-DIM-thumbnail"/>
                        </xsl:if>
                    </div>
                    <xsl:call-template name="itemSummaryView-DIM-file-section"/>
                    <xsl:call-template name="itemSummaryView-DIM-date"/>
                    <xsl:call-template name="itemSummaryView-DIM-authors"/>
                    <xsl:call-template name="itemSummaryView-DIM-supervisors"/>
                    <xsl:call-template name="itemSummaryView-DIM-sponsors"/>
                    <xsl:call-template name="itemSummaryView-DIM-grantnumbers"/>

                    <xsl:call-template name="itemSummaryView-DIM-keywords"/>
                    <xsl:if test="$ds_item_view_toggle_url != ''">
                    <xsl:call-template name="itemSummaryView-show-full"/>
                    </xsl:if>
                    <xsl:call-template name="itemAltmetricsDonut"/>
                </div>
                <div class="col-sm-8">
                    <xsl:call-template name="itemSummaryView-DIM-abstract"/>
                    <xsl:call-template name="itemSummaryView-DIM-citation"/>
                    <!--<xsl:call-template name="itemSummaryView-DIM-version"/>-->
                    <xsl:call-template name="itemSummaryView-DIM-publication"/>
                    <xsl:call-template name="itemSummaryView-DIM-status"/>
                    <xsl:call-template name="itemSummaryView-DIM-DOI"/>
                    <xsl:call-template name="itemSummaryView-DIM-ISSN"/>
                    <xsl:call-template name="itemSummaryView-DIM-type"/>
                    <xsl:call-template name="itemSummaryView-DIM-rights"/>
                    <xsl:call-template name="itemSummaryView-DIM-description"/>
                    <!--<xsl:call-template name="itemSummaryView-DIM-rightsURI"/>-->
                    <xsl:call-template name="itemSummaryView-collections"/>
                    <xsl:call-template name="itemSummaryView-DIM-relation"/>
                    <xsl:call-template name="itemSummaryView-DIM-URL"/>
                    <xsl:call-template name="itemSummaryView-DIM-URI"/>
                </div>
            </div>
        </div>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-title">
        <xsl:choose>
            <xsl:when test="count(dim:field[@element='title'][not(@qualifier)]) &gt; 1">
                <h2 class="page-header first-page-header">
                    <xsl:value-of select="dim:field[@element='title'][not(@qualifier)][1]/node()"/>
                </h2>
                <div class="simple-item-view-other">
                    <p class="lead">
                        <xsl:for-each select="dim:field[@element='title'][not(@qualifier)]">
                            <xsl:if test="not(position() = 1)">
                                <xsl:value-of select="./node()"/>
                                <xsl:if test="count(following-sibling::dim:field[@element='title'][not(@qualifier)]) != 0">
                                    <xsl:text>; </xsl:text>
                                    <br/>
                                </xsl:if>
                            </xsl:if>

                        </xsl:for-each>
                    </p>
                </div>
            </xsl:when>
            <xsl:when test="count(dim:field[@element='title'][not(@qualifier)]) = 1">
                <h2 class="page-header first-page-header">
                    <xsl:value-of select="dim:field[@element='title'][not(@qualifier)][1]/node()"/>
                </h2>
            </xsl:when>
            <xsl:otherwise>
                <h2 class="page-header first-page-header">
                    <i18n:text>xmlui.dri2xhtml.METS-1.0.no-title</i18n:text>
                </h2>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-thumbnail">

        <xsl:variable name="primaryBitstream" select="//mets:structMap[@TYPE='LOGICAL']/mets:div[@TYPE='DSpace Item']/mets:fptr/@FILEID"/>

        <!-- Only display thumbnail stuff is a thumbnail exists. -->
        <xsl:if test="/mets:METS/mets:fileSec/mets:fileGrp[@USE='THUMBNAIL']/mets:file[@GROUPID=../../mets:fileGrp[@USE='CONTENT']/mets:file[@GROUPID=../../mets:fileGrp[@USE='THUMBNAIL']/mets:file/@GROUPID][1]/@GROUPID]">

            <div class="thumbnail">
                <xsl:choose>
                    <xsl:when test="//mets:fileSec/mets:fileGrp[@USE='THUMBNAIL']">
                        <xsl:variable name="src">
                            <xsl:choose>
                                <xsl:when test="/mets:METS/mets:fileSec/mets:fileGrp[@USE='THUMBNAIL']/mets:file[@GROUPID=../../mets:fileGrp[@USE='CONTENT']/mets:file[@GROUPID=../../mets:fileGrp[@USE='THUMBNAIL']/mets:file/@GROUPID][1]/@GROUPID]">
                                    <xsl:value-of
                                            select="/mets:METS/mets:fileSec/mets:fileGrp[@USE='THUMBNAIL']/mets:file[@GROUPID=../../mets:fileGrp[@USE='CONTENT']/mets:file[@GROUPID=../../mets:fileGrp[@USE='THUMBNAIL']/mets:file/@GROUPID][1]/@GROUPID]/mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of
                                            select="//mets:fileSec/mets:fileGrp[@USE='THUMBNAIL']/mets:file/mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>

                        <xsl:variable name="shortenedsrc">
                            <!--<xsl:choose>
                                <xsl:when test="contains($src, '?')">
                                    <xsl:value-of select="substring($src, 1, string-length(substring-before($src,'?')) - 4)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="substring($src, 1, string-length($src) - 4)"/>
                                </xsl:otherwise>
                            </xsl:choose>-->
                            <xsl:value-of select="concat(substring-before($src,'.jpg'), '.jpg')"/>
                        </xsl:variable>
                        <a>
                        <xsl:attribute name="href">
                            <!--xsl:value-of select="$shortenedsrc"/-->
                            <!--<xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>-->
                            <xsl:choose>
                                <xsl:when test="$primaryBitstream != ''">
                                    <xsl:value-of select="//mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL']/mets:file[@ID=$primaryBitstream]/mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                                </xsl:when>
                                <xsl:otherwise>
                                        <xsl:value-of select="//mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL']/mets:file/mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                        </xsl:attribute>

                        <!-- Checking if Thumbnail is restricted and if so, show a restricted image -->
                        <xsl:choose>
                            <xsl:when test="contains($src,'isAllowed=n')"/>
                            <xsl:otherwise>
                                <img class="img-thumbnail" alt="Thumbnail">
                                    <xsl:attribute name="src">
                                        <xsl:value-of select="$src"/>
                                    </xsl:attribute>
                                </img>
                            </xsl:otherwise>
                        </xsl:choose>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <img class="img-thumbnail" alt="Thumbnail">
                            <xsl:attribute name="data-src">
                                <xsl:text>holder.js/100%x</xsl:text>
                                <xsl:value-of select="$thumbnail.maxheight"/>
                                <xsl:text>/text:No Thumbnail</xsl:text>
                            </xsl:attribute>
                        </img>
                    </xsl:otherwise>
                </xsl:choose>
            </div>

        </xsl:if>

    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-abstract">
        <xsl:if test="dim:field[@element='description' and @qualifier='abstract']">
            <div class="simple-item-view-description item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-abstract</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@element='description' and @qualifier='abstract']">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:copy-of select="node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='description' and @qualifier='abstract']) != 0">
                            <div class="spacer">&#160;</div>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count(dim:field[@element='description' and @qualifier='abstract']) &gt; 1">
                        <div class="spacer">&#160;</div>
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-authors">
        <xsl:if test="dim:field[@element='contributor'][@qualifier='author' and descendant::text()] or dim:field[@element='creator' and descendant::text()] or dim:field[@element='contributor' and descendant::text()]">
            <div class="simple-item-view-authors item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-author</i18n:text></h5>
                <xsl:choose>
                    <xsl:when test="dim:field[@element='contributor'][@qualifier='author']">
                        <xsl:for-each select="dim:field[@element='contributor'][@qualifier='author']">
                            <xsl:call-template name="itemSummaryView-DIM-authors-entry" />
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:when test="dim:field[@element='creator']">
                        <xsl:for-each select="dim:field[@element='creator']">
                            <xsl:call-template name="itemSummaryView-DIM-authors-entry" />
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:when test="dim:field[@element='contributor']">
                        <xsl:for-each select="dim:field[@element='contributor']">
                            <xsl:call-template name="itemSummaryView-DIM-authors-entry" />
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.no-author</i18n:text>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-supervisors">
        <xsl:if test="dim:field[@element='contributor' and @qualifier='advisor']">
            <div class="simple-item-view-supervisor item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-supervisor</i18n:text></h5>
                <xsl:for-each select="dim:field[@element='contributor' and @qualifier='advisor']">
                    <div>
                        <a>
                            <xsl:attribute name="href">
                                <xsl:value-of select="(concat($context-path,'/browse?type=names&amp;value='))"/>
                                <xsl:copy-of select="encoder:encode(node())"/>
                            </xsl:attribute>
                            <xsl:value-of select="text()"/>
                        </a>
                    </div>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-authors-entry">
        <div>
            <xsl:if test="@authority">
                <xsl:attribute name="class"><xsl:text>ds-dc_contributor_author-authority</xsl:text></xsl:attribute>
            </xsl:if>
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="(concat($context-path,'/browse?type=names&amp;value='))"/>
                    <xsl:copy-of select="encoder:encode(node())"/>
                </xsl:attribute>
                <xsl:value-of select="text()"/>
            </a>

            <xsl:if test="@orcid_id">
                <xsl:text> </xsl:text>
                <a href="https://orcid.org/{@orcid_id}" target="_blank"><img src="{$theme-path}/images/orcid_16x16.png" alt="ORCID" /></a>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-sponsors">
        <xsl:if test="dim:field[@element='contributor' and @qualifier='sponsor']">
            <div class="simple-item-view-sponsors item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-sponsor</i18n:text></h5>
                <xsl:for-each select="dim:field[@element='contributor' and @qualifier='sponsor']">
                    <div>
                        <a>
                            <xsl:attribute name="href">
                                <xsl:value-of select="(concat($context-path,'/browse?type=sponsor&amp;value='))"/>
                                <xsl:copy-of select="encoder:encode(node())"/>
                            </xsl:attribute>
                            <xsl:value-of select="text()"/>
                        </a>
                    </div>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-grantnumbers">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='grantnumber']">
            <div class="simple-item-view-keywords item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-grantnumber</i18n:text></h5>
                <xsl:for-each select="dim:field[@element='identifier' and @qualifier='grantnumber']">
                    <div>
                        <!--<a>
                            <xsl:attribute name="href">
                                <xsl:value-of select="(concat($context-path,'/browse?type=subject&amp;value='))"/>
                                <xsl:copy-of select="encoder:encode(node())"/>
                            </xsl:attribute>-->
                            <xsl:value-of select="text()"/>
                        <!--</a>-->
                    </div>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>


    <xsl:template name="itemSummaryView-DIM-keywords">
        <xsl:if test="dim:field[@element='subject'][not(@qualifier)]">
            <div class="simple-item-view-keywords item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-keywords</i18n:text></h5>
                <xsl:for-each select="dim:field[@element='subject'][not(@qualifier)]">
                    <div>
                        <a>
                            <xsl:attribute name="href">
                                <xsl:value-of select="(concat($context-path,'/browse?type=subject&amp;value='))"/>
                                <xsl:copy-of select="encoder:encode(node())"/>
                            </xsl:attribute>
                            <xsl:value-of select="text()"/>
                        </a>
                    </div>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-URL">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='url' and descendant::text()]">
            <div class="simple-item-view-uri item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-url</i18n:text></h5>
                <span>
                    <xsl:for-each select="dim:field[@element='identifier' and @qualifier='url']">
                        <a>
                            <xsl:attribute name="href">
                                <xsl:copy-of select="./node()"/>
                            </xsl:attribute>
                            <xsl:copy-of select="./node()"/>
                        </a>
                        <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='url']) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-URI">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='uri' and descendant::text()]">
            <div class="simple-item-view-uri item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-uri</i18n:text></h5>
                <span>
                    <xsl:for-each select="dim:field[@element='identifier' and @qualifier='uri']">
                        <a>
                            <xsl:attribute name="href">
                                <xsl:copy-of select="./node()"/>
                            </xsl:attribute>
                            <xsl:copy-of select="./node()"/>
                        </a>
                        <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='uri']) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-DOI">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='doi' and descendant::text()]">
            <div class="simple-item-view-doi item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-doi</i18n:text></h5>
                <span>
                    <xsl:for-each select="dim:field[@element='identifier' and @qualifier='doi']">
                        <a>
                            <xsl:attribute name="href">
                                <xsl:copy-of select="./node()"/>
                            </xsl:attribute>
                            <xsl:copy-of select="./node()"/>
                        </a>
                        <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='doi']) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template name="itemSummaryView-DIM-ISSN">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='issn' and descendant::text()]">
            <div class="simple-item-view-doi item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-issn</i18n:text></h5>
                <span>
                    <xsl:for-each select="dim:field[@element='identifier' and @qualifier='issn']">
                        <xsl:copy-of select="./node()"/>
                        <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='issn']) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-date">
        <xsl:if test="dim:field[@element='date' and @qualifier='issued' and descendant::text()]">
            <div class="simple-item-view-date word-break item-page-field-wrapper table">
                <h5>
                    <i18n:text>xmlui.dri2xhtml.METS-1.0.item-date</i18n:text>
                </h5>
                <xsl:for-each select="dim:field[@element='date' and @qualifier='issued']">
                    <xsl:call-template name="formatdate">
                        <xsl:with-param name="datestr" select="substring(./node(),1,10)"/>
                    </xsl:call-template>
                    <xsl:if test="count(following-sibling::dim:field[@element='date' and @qualifier='issued']) != 0">
                        <br/>
                    </xsl:if>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-type">
        <xsl:if test="dim:field[@element='type']">
            <div class="simple-item-view-type item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-type</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@element='type'][not(@qualifier)]">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:copy-of select="node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='type'][not(@qualifier)]) != 0">
                            <div class="spacer">&#160;</div>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count(dim:field[@element='type'][not(@qualifier)]) &gt; 1">
                        <div class="spacer">&#160;</div>
                    </xsl:if>
                    <xsl:for-each select="dim:field[@element='type' and @qualifier = 'qualificationname']">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:text>&#44;&#160;</xsl:text>
                                <xsl:copy-of select="node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='type' and @qualifier = 'qualificationname']) != 0">
                            <div class="spacer">&#160;</div>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count(dim:field[@element='type' and @qualifier = 'qualificationname']) &gt; 1">
                        <div class="spacer">&#160;</div>
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-description">
        <xsl:if test="dim:field[@element='description'][not(@qualifier)]">
            <div class="simple-item-view-uri item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-description</i18n:text></h5>
                <span>
                    <xsl:for-each select="dim:field[@element='description'][not(@qualifier)]">
                        <xsl:copy-of select="./node()"/>
                        <xsl:if test="count(following-sibling::dim:field[@element='description'][not(@qualifier)]) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template name="itemSummaryView-DIM-relation">
        <!--<xsl:choose>  -->
        <xsl:if test="dim:field[@element='relation'][not(@qualifier)]">
            <div class="simple-item-view-uri item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-relation</i18n:text></h5>
                <span>
                    <xsl:for-each select="dim:field[@element='relation'][not(@qualifier)]">
                        <xsl:copy-of select="./node()"/>
                        <xsl:if test="count(following-sibling::dim:field[@element='relation']) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>
        <xsl:if test="dim:field[@element='relation' and @qualifier='uri' and descendant::text()]">
            <div class="simple-item-view-uri item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-relation-uri</i18n:text></h5>
                <span>
                    <xsl:for-each select="dim:field[@element='relation' and @qualifier = 'uri']">
                        <a>
                            <xsl:attribute name="href">
                                <xsl:copy-of select="./node()"/>
                            </xsl:attribute>
                            <xsl:copy-of select="./node()"/>
                        </a>
                        <xsl:if test="count(following-sibling::dim:field[@element='relation' and @qualifier = 'uri']) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>
        <!--<xsl:if test="dim:field[@element='relation' and @qualifier!='uri']">
            <div class="simple-item-view-uri item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-relation-generic</i18n:text></h5>
                <span>
                    <xsl:for-each select="dim:field[@element='relation' and @qualifier!='uri']">
                        <xsl:copy-of select="./node()"/>
                        <xsl:if test="count(following-sibling::dim:field[@element='relation']) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>   -->
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-rights">
        <xsl:if test="dim:field[@element='rights']">
            <div class="simple-item-view-rights item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-rights</i18n:text></h5>
                <xsl:if test="dim:field[@element='rights'][not(@qualifier)]">
                    <div>
                        <xsl:for-each select="dim:field[@element='rights'][not(@qualifier)]">
                            <xsl:choose>
                                <xsl:when test="node()">
                                    <xsl:copy-of select="node()"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>&#160;</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="count(following-sibling::dim:field[@element='rights'][not(@qualifier)]) != 0">
                                <div class="spacer">&#160;</div>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:if test="count(dim:field[@element='rights'][not(@qualifier)]) &gt; 1">
                            <!--<div class="spacer">&#160;</div>-->
                            <br/>
                        </xsl:if>
                    </div>
                </xsl:if>
                <xsl:if test="dim:field[@element='rights' and @qualifier='uri' and descendant::text()]">
                    <span>
                        <xsl:for-each select="dim:field[@element='rights' and @qualifier='uri']">
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:copy-of select="./node()"/>
                                </xsl:attribute>
                                <xsl:copy-of select="./node()"/>
                            </a>
                            <xsl:if test="count(following-sibling::dim:field[@element='rights' and @qualifier='uri']) != 0">
                                <br/>
                            </xsl:if>
                        </xsl:for-each>
                    </span>
                </xsl:if>
                <xsl:if test="dim:field[@element='rights' and @qualifier='embargodate' and descendant::text()]">
                    <div>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.item-rights-embargodate</i18n:text><xsl:text>: </xsl:text>
                        <xsl:for-each select="dim:field[@element='rights' and @qualifier='embargodate']">
                            <xsl:choose>
                                <xsl:when test="node()">
                                    <xsl:copy-of select="node()"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>&#160;</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="count(following-sibling::dim:field[@element='rights' and @qualifier='embargodate']) != 0">
                                <!--<div class="spacer">&#160;</div>-->
                                <br/>
                            </xsl:if>
                        </xsl:for-each>
                    </div>
                </xsl:if>
                <xsl:if test="dim:field[@element='rights' and @qualifier='embargoreason' and descendant::text()]">
                    <div>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.item-rights-embargoreason</i18n:text><xsl:text>: </xsl:text>
                        <xsl:for-each select="dim:field[@element='rights' and @qualifier='embargoreason']">
                            <xsl:choose>
                                <xsl:when test="node()">
                                    <xsl:copy-of select="node()"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>&#160;</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="count(following-sibling::dim:field[@element='rights' and @qualifier='embargoreason']) != 0">
                                <!--<div class="spacer">&#160;</div>-->
                                <br/>
                            </xsl:if>
                        </xsl:for-each>
                    </div>
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-rightsURI">
        <!--<xsl:if test="dim:field[@element='rights' and @qualifier='uri' and descendant::text()]">
            <div class="simple-item-view-rights-uri item-page-field-wrapper table">
                <span>
                    <xsl:for-each select="dim:field[@element='rights' and @qualifier='uri']">
                        <a>
                            <xsl:attribute name="href">
                                <xsl:copy-of select="./node()"/>
                            </xsl:attribute>
                            <xsl:copy-of select="./node()"/>
                        </a>
                        <xsl:if test="count(following-sibling::dim:field[@element='rights' and @qualifier='uri']) != 0">
                            <br/>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </div>
        </xsl:if>-->
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-publication">
        <xsl:if test="dim:field[@element='relation' and @qualifier = 'ispartof']">
            <div class="simple-item-view-publication item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-publication</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@element='relation' and @qualifier = 'ispartof']">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:copy-of select="node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='relation' and @qualifier = 'ispartof']) != 0">
                            <div class="spacer">&#160;</div>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count(dim:field[@element='relation' and @qualifier = 'ispartof']) &gt; 1">
                        <div class="spacer">&#160;</div>
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <!--<xsl:template name="itemSummaryView-DIM-description">
        <xsl:if test="dim:field[@element='decription'][not(@qualifier)]">
            <div class="simple-item-view-description item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-description</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@element='description'][not(@qualifier)]">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:copy-of select="node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='description'][not(@qualifier)]) != 0">
                            <div class="spacer">&#160;</div>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count(dim:field[@element='description'][not(@qualifier)]) &gt; 1">
                        <div class="spacer">&#160;</div>
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
    </xsl:template>-->

    <!--<xsl:template name="itemSummaryView-DIM-version">
        <xsl:if test="dim:field[@element='description' and @qualifier='version']">
            <div class="simple-item-view-relation item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-version</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@element='description' and @qualifier='version']">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:copy-of select="node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='description' and @qualifier='version']) != 0">
                            <div class="spacer">&#160;</div>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count(dim:field[@element='description' and @qualifier='version']) &gt; 1">
                        <div class="spacer">&#160;</div>
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
    </xsl:template>-->

    <xsl:template name="itemSummaryView-DIM-status">
        <xsl:if test="dim:field[@element='description' and @qualifier='status']">
            <div class="simple-item-view-relation item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-status</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@element='description' and @qualifier='status']">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:copy-of select="node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='description' and @qualifier='status']) != 0">
                            <div class="spacer">&#160;</div>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count(dim:field[@element='description' and @qualifier='status']) &gt; 1">
                        <div class="spacer">&#160;</div>
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-citation">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='citation']">
            <div class="simple-item-view-relation item-page-field-wrapper table">
                <h5><i18n:text>xmlui.dri2xhtml.METS-1.0.item-citation</i18n:text></h5>
                <div>
                    <xsl:for-each select="dim:field[@element='identifier' and @qualifier='citation']">
                        <xsl:choose>
                            <xsl:when test="node()">
                                <xsl:copy-of select="node()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>&#160;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='citation']) != 0">
                            <div class="spacer">&#160;</div>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:if test="count(dim:field[@element='identifier' and @qualifier='citation']) &gt; 1">
                        <div class="spacer">&#160;</div>
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-show-full">
        <div class="simple-item-view-show-full item-page-field-wrapper table">
            <h5>
                <i18n:text>xmlui.mirage2.itemSummaryView.MetaData</i18n:text>
            </h5>
            <a>
                <xsl:attribute name="href"><xsl:value-of select="$ds_item_view_toggle_url"/></xsl:attribute>
                <i18n:text>xmlui.ArtifactBrowser.ItemViewer.show_full</i18n:text>
            </a>
        </div>
    </xsl:template>

    <xsl:template name="itemAltmetricsDonut">
        <xsl:if test="dim:field[@element='identifier' and @qualifier='uri' and descendant::text()]">
            <h5 class="altmet-handle-head">
                <i18n:text>xmlui.dri2xhtml.METS-1.0.item-altmetrics-handle</i18n:text>
            </h5>
            <div class='altmetric-embed altmet-handle' data-badge-type='donut' data-hide-less-than='1'>
                <xsl:attribute name="data-handle">
                    <xsl:value-of select="substring(dim:field[@element='identifier' and @qualifier='uri' and descendant::text()],23)"/>
                </xsl:attribute>
            </div>
        </xsl:if>
        <xsl:if test="dim:field[@element='identifier' and @qualifier='doi' and descendant::text()]">
            <h5 class="altmet-doi-head">
                <i18n:text>xmlui.dri2xhtml.METS-1.0.item-altmetrics-doi</i18n:text>
            </h5>
            <div class='altmetric-embed altmet-doi' data-badge-type='donut' data-hide-less-than='1'>
                <xsl:attribute name="data-doi">
                    <xsl:value-of select="substring(dim:field[@element='identifier' and @qualifier='doi' and descendant::text()],17)"/>
                </xsl:attribute>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-collections">
        <xsl:if test="$document//dri:referenceSet[@id='aspect.artifactbrowser.ItemViewer.referenceSet.collection-viewer']">
            <div class="simple-item-view-collections item-page-field-wrapper table">
                <h5>
                    <i18n:text>xmlui.mirage2.itemSummaryView.Collections</i18n:text>
                </h5>
                <xsl:apply-templates select="$document//dri:referenceSet[@id='aspect.artifactbrowser.ItemViewer.referenceSet.collection-viewer']/dri:reference"/>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-file-section">
        <xsl:choose>
            <xsl:when test="//mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL']/mets:file">
                <div class="item-page-field-wrapper table">
                    <h5>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-viewOpen</i18n:text>
                    </h5>

                    <xsl:variable name="label-1">
                            <xsl:choose>
                                <xsl:when test="confman:getProperty('mirage2.item-view.bitstream.href.label.1')">
                                    <xsl:value-of select="confman:getProperty('mirage2.item-view.bitstream.href.label.1')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>label</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                    </xsl:variable>

                    <xsl:variable name="label-2">
                            <xsl:choose>
                                <xsl:when test="confman:getProperty('mirage2.item-view.bitstream.href.label.2')">
                                    <xsl:value-of select="confman:getProperty('mirage2.item-view.bitstream.href.label.2')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>title</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                    </xsl:variable>

                    <xsl:for-each select="//mets:fileSec/mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL']/mets:file">
                        <xsl:call-template name="itemSummaryView-DIM-file-section-entry">
                            <xsl:with-param name="href" select="mets:FLocat[@LOCTYPE='URL']/@xlink:href" />
                            <xsl:with-param name="mimetype" select="@MIMETYPE" />
                            <xsl:with-param name="label-1" select="$label-1" />
                            <xsl:with-param name="label-2" select="$label-2" />
                            <xsl:with-param name="title" select="mets:FLocat[@LOCTYPE='URL']/@xlink:title" />
                            <xsl:with-param name="label" select="mets:FLocat[@LOCTYPE='URL']/@xlink:label" />
                            <xsl:with-param name="size" select="@SIZE" />
                        </xsl:call-template>
                    </xsl:for-each>
                </div>
            </xsl:when>
            <!-- Special case for handling ORE resource maps stored as DSpace bitstreams -->
            <xsl:when test="//mets:fileSec/mets:fileGrp[@USE='ORE']">
                <xsl:apply-templates select="//mets:fileSec/mets:fileGrp[@USE='ORE']" mode="itemSummaryView-DIM" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="itemSummaryView-DIM-file-section-entry">
        <xsl:param name="href" />
        <xsl:param name="mimetype" />
        <xsl:param name="label-1" />
        <xsl:param name="label-2" />
        <xsl:param name="title" />
        <xsl:param name="label" />
        <xsl:param name="size" />
        <div class="word-wrap">
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:label"/>
                </xsl:attribute>
                <xsl:call-template name="getFileIcon">
                    <xsl:with-param name="mimetype">
                        <xsl:value-of select="substring-before(@MIMETYPE,'/')"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="substring-after(@MIMETYPE,'/')"/>
                    </xsl:with-param>
                </xsl:call-template>
                <xsl:choose>
                    <xsl:when test="contains($label-1, 'label') and mets:FLocat[@LOCTYPE='URL']/@xlink:label">
                        <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:label"/>
                    </xsl:when>
                    <xsl:when test="contains($label-1, 'title') and mets:FLocat[@LOCTYPE='URL']/@xlink:title">
                        <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:title"/>
                    </xsl:when>
                    <xsl:when test="contains($label-2, 'label') and mets:FLocat[@LOCTYPE='URL']/@xlink:label">
                        <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:label"/>
                    </xsl:when>
                    <xsl:when test="contains($label-2, 'title') and mets:FLocat[@LOCTYPE='URL']/@xlink:title">
                        <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:title"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="getFileTypeDesc">
                            <xsl:with-param name="mimetype">
                                <xsl:value-of select="substring-before(@MIMETYPE,'/')"/>
                                <xsl:text>/</xsl:text>
                                <xsl:choose>
                                    <xsl:when test="contains(@MIMETYPE,';')">
                                        <xsl:value-of select="substring-before(substring-after(@MIMETYPE,'/'),';')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="substring-after(@MIMETYPE,'/')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> (</xsl:text>
                <xsl:choose>
                    <xsl:when test="@SIZE &lt; 1024">
                        <xsl:value-of select="@SIZE"/>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-bytes</i18n:text>
                    </xsl:when>
                    <xsl:when test="@SIZE &lt; 1024 * 1024">
                        <xsl:value-of select="substring(string(@SIZE div 1024),1,5)"/>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-kilobytes</i18n:text>
                    </xsl:when>
                    <xsl:when test="@SIZE &lt; 1024 * 1024 * 1024">
                        <xsl:value-of select="substring(string(@SIZE div (1024 * 1024)),1,5)"/>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-megabytes</i18n:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring(string(@SIZE div (1024 * 1024 * 1024)),1,5)"/>
                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-gigabytes</i18n:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>)</xsl:text>
            </a>
        </div>
    </xsl:template>

    <xsl:template match="dim:dim" mode="itemDetailView-DIM">
        <xsl:call-template name="itemSummaryView-DIM-title"/>
        <h3><i18n:text>xmlui.dri2xhtml.METS-1.0.item-metadata-head</i18n:text></h3>
        <div class="ds-table-responsive">
            <table class="ds-includeSet-table detailtable table table-striped table-hover">
                <xsl:apply-templates mode="itemDetailView-DIM"/>
            </table>
        </div>

        <span class="Z3988">
            <xsl:attribute name="title">
                 <xsl:call-template name="renderCOinS"/>
            </xsl:attribute>
            &#xFEFF; <!-- non-breaking space to force separating the end tag -->
        </span>
        <xsl:copy-of select="$SFXLink" />
    </xsl:template>

    <xsl:template match="dim:field" mode="itemDetailView-DIM">
            <tr>
                <xsl:attribute name="class">
                    <xsl:text>ds-table-row </xsl:text>
                    <xsl:if test="(position() div 2 mod 2 = 0)">even </xsl:if>
                    <xsl:if test="(position() div 2 mod 2 = 1)">odd </xsl:if>
                </xsl:attribute>
                <td class="label-cell">
                    <xsl:value-of select="./@mdschema"/>
                    <xsl:text>.</xsl:text>
                    <xsl:value-of select="./@element"/>
                    <xsl:if test="./@qualifier">
                        <xsl:text>.</xsl:text>
                        <xsl:value-of select="./@qualifier"/>
                    </xsl:if>
                </td>
            <td class="word-break">
              <xsl:copy-of select="./node()"/>
            </td>
                <td><xsl:value-of select="./@language"/></td>
            </tr>
    </xsl:template>

    <!-- don't render the item-view-toggle automatically in the summary view, only when it gets called -->
    <xsl:template match="dri:p[contains(@rend , 'item-view-toggle') and
        (preceding-sibling::dri:referenceSet[@type = 'summaryView'] or following-sibling::dri:referenceSet[@type = 'summaryView'])]">
    </xsl:template>

    <!-- don't render the head on the item view page -->
    <xsl:template match="dri:div[@n='item-view']/dri:head" priority="5">
    </xsl:template>

   <xsl:template match="mets:fileGrp[@USE='CONTENT' or @USE='ORIGINAL']">
        <xsl:param name="context"/>
        <xsl:param name="primaryBitstream" select="-1"/>
            <xsl:choose>
                <!-- If one exists and it's of text/html MIME type, only display the primary bitstream -->
                <xsl:when test="mets:file[@ID=$primaryBitstream]/@MIMETYPE='text/html'">
                    <xsl:apply-templates select="mets:file[@ID=$primaryBitstream]">
                        <xsl:with-param name="context" select="$context"/>
                    </xsl:apply-templates>
                </xsl:when>
                <!-- Otherwise, iterate over and display all of them -->
                <xsl:otherwise>
                    <xsl:apply-templates select="mets:file">
                     	<!--Do not sort any more bitstream order can be changed-->
                        <xsl:with-param name="context" select="$context"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
    </xsl:template>

   <xsl:template match="mets:fileGrp[@USE='LICENSE']">
        <xsl:param name="context"/>
        <xsl:param name="primaryBitstream" select="-1"/>
            <xsl:apply-templates select="mets:file">
                        <xsl:with-param name="context" select="$context"/>
            </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="mets:file">
        <xsl:param name="context" select="."/>
        <xsl:variable select="mets:FLocat[@LOCTYPE='URL']/@xlink:href" name="imageURL"/>
        <div class="file-wrapper row">

            <xsl:choose>

                <!-- Only display thumbnail stuff is a thumbnail exists. -->
                <xsl:when test="$context/mets:fileSec/mets:fileGrp[@USE='THUMBNAIL']/mets:file[@GROUPID=current()/@GROUPID]">

                    <div class="col-xs-6 col-sm-3">
                        <div class="thumbnail">
                            <a class="image-link">
                                <!--<xsl:attribute name="href">
                                    <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                                </xsl:attribute>-->
                                <xsl:choose>
                                    <xsl:when test="$context/mets:fileSec/mets:fileGrp[@USE='THUMBNAIL']/
                                mets:file[@GROUPID=current()/@GROUPID]">
                                        <xsl:variable name="src">
                                            <xsl:value-of select="$context/mets:fileSec/mets:fileGrp[@USE='THUMBNAIL']/
                                            mets:file[@GROUPID=current()/@GROUPID]/mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
                                        </xsl:variable>
                                        <xsl:variable name="shortenedsrc">
                                            <xsl:value-of select="concat(substring-before($src,'.jpg'), '.jpg')"/>
                                        </xsl:variable>
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="$shortenedsrc"/>
                                        </xsl:attribute>
                                        <img alt="Thumbnail">
                                            <xsl:attribute name="src">
                                                <!--<xsl:value-of select="$context/mets:fileSec/mets:fileGrp[@USE='THUMBNAIL']/
                                            mets:file[@GROUPID=current()/@GROUPID]/mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>-->
                                                <xsl:value-of select="$src"/>
                                            </xsl:attribute>
                                        </img>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <img alt="Thumbnail">
                                            <xsl:attribute name="data-src">
                                                <xsl:text>holder.js/100%x</xsl:text>
                                                <xsl:value-of select="$thumbnail.maxheight"/>
                                                <xsl:text>/text:No Thumbnail</xsl:text>
                                            </xsl:attribute>
                                        </img>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </a>
                        </div>
                    </div>

                    <div class="col-xs-6 col-sm-7">
                        <dl class="file-metadata dl-horizontal">
                            <dt>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-name</i18n:text>
                                <xsl:text>:</xsl:text>
                            </dt>
                            <dd class="word-break">
                                <xsl:attribute name="title">
                                    <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:title"/>
                                </xsl:attribute>
                                <!--<xsl:value-of select="util:shortenString(mets:FLocat[@LOCTYPE='URL']/@xlink:title, 50, 5)"/>-->
                                <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:title"/>
                            </dd>
                            <!-- File size always comes in bytes and thus needs conversion -->
                            <dt>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-size</i18n:text>
                                <xsl:text>:</xsl:text>
                            </dt>
                            <dd class="word-break">
                                <xsl:choose>
                                    <xsl:when test="@SIZE &lt; 1024">
                                        <xsl:value-of select="@SIZE"/>
                                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-bytes</i18n:text>
                                    </xsl:when>
                                    <xsl:when test="@SIZE &lt; 1024 * 1024">
                                        <xsl:value-of select="substring(string(@SIZE div 1024),1,5)"/>
                                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-kilobytes</i18n:text>
                                    </xsl:when>
                                    <xsl:when test="@SIZE &lt; 1024 * 1024 * 1024">
                                        <xsl:value-of select="substring(string(@SIZE div (1024 * 1024)),1,5)"/>
                                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-megabytes</i18n:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="substring(string(@SIZE div (1024 * 1024 * 1024)),1,5)"/>
                                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-gigabytes</i18n:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </dd>
                            <!-- Lookup File Type description in local messages.xml based on MIME Type.
                     In the original DSpace, this would get resolved to an application via
                     the Bitstream Registry, but we are constrained by the capabilities of METS
                     and can't really pass that info through. -->
                            <dt>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-format</i18n:text>
                                <xsl:text>:</xsl:text>
                            </dt>
                            <dd class="word-break">
                                <xsl:call-template name="getFileTypeDesc">
                                    <xsl:with-param name="mimetype">
                                        <xsl:value-of select="substring-before(@MIMETYPE,'/')"/>
                                        <xsl:text>/</xsl:text>
                                        <xsl:choose>
                                            <xsl:when test="contains(@MIMETYPE,';')">
                                                <xsl:value-of select="substring-before(substring-after(@MIMETYPE,'/'),';')"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="substring-after(@MIMETYPE,'/')"/>
                                            </xsl:otherwise>
                                        </xsl:choose>

                                    </xsl:with-param>
                                </xsl:call-template>
                            </dd>
                            <!-- Display the contents of 'Description' only if bitstream contains a description -->
                            <xsl:if test="mets:FLocat[@LOCTYPE='URL']/@xlink:label != ''">
                                <dt>
                                    <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-description</i18n:text>
                                    <xsl:text>:</xsl:text>
                                </dt>
                                <dd class="word-break">
                                    <xsl:attribute name="title">
                                        <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:label"/>
                                    </xsl:attribute>
                                    <!--<xsl:value-of select="util:shortenString(mets:FLocat[@LOCTYPE='URL']/@xlink:label, 50, 5)"/>-->
                                    <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:label"/>
                                </dd>
                            </xsl:if>
                        </dl>
                    </div>

                    <div class="file-link col-xs-6 col-xs-offset-6 col-sm-2 col-sm-offset-0">
                        <xsl:choose>
                            <xsl:when test="@ADMID">
                                <xsl:call-template name="display-rights"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="view-open"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </div>

                </xsl:when>

                <xsl:otherwise>
                    <!-- No thumbnail stuff. -->

                    <div class="col-xs-8">
                        <dl class="file-metadata dl-horizontal no-thumbnail">
                            <dt>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-name</i18n:text>
                                <xsl:text>:</xsl:text>
                            </dt>
                            <dd class="word-break">
                                <xsl:attribute name="title">
                                    <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:title"/>
                                </xsl:attribute>
                                <!--<xsl:value-of select="util:shortenString(mets:FLocat[@LOCTYPE='URL']/@xlink:title, 50, 5)"/>-->
                                <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:title"/>
                            </dd>
                            <!-- File size always comes in bytes and thus needs conversion -->
                            <dt>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-size</i18n:text>
                                <xsl:text>:</xsl:text>
                            </dt>
                            <dd class="word-break">
                                <xsl:choose>
                                    <xsl:when test="@SIZE &lt; 1024">
                                        <xsl:value-of select="@SIZE"/>
                                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-bytes</i18n:text>
                                    </xsl:when>
                                    <xsl:when test="@SIZE &lt; 1024 * 1024">
                                        <xsl:value-of select="substring(string(@SIZE div 1024),1,5)"/>
                                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-kilobytes</i18n:text>
                                    </xsl:when>
                                    <xsl:when test="@SIZE &lt; 1024 * 1024 * 1024">
                                        <xsl:value-of select="substring(string(@SIZE div (1024 * 1024)),1,5)"/>
                                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-megabytes</i18n:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="substring(string(@SIZE div (1024 * 1024 * 1024)),1,5)"/>
                                        <i18n:text>xmlui.dri2xhtml.METS-1.0.size-gigabytes</i18n:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </dd>
                            <!-- Lookup File Type description in local messages.xml based on MIME Type.
                     In the original DSpace, this would get resolved to an application via
                     the Bitstream Registry, but we are constrained by the capabilities of METS
                     and can't really pass that info through. -->
                            <dt>
                                <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-format</i18n:text>
                                <xsl:text>:</xsl:text>
                            </dt>
                            <dd class="word-break">
                                <xsl:call-template name="getFileTypeDesc">
                                    <xsl:with-param name="mimetype">
                                        <xsl:value-of select="substring-before(@MIMETYPE,'/')"/>
                                        <xsl:text>/</xsl:text>
                                        <xsl:choose>
                                            <xsl:when test="contains(@MIMETYPE,';')">
                                                <xsl:value-of select="substring-before(substring-after(@MIMETYPE,'/'),';')"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="substring-after(@MIMETYPE,'/')"/>
                                            </xsl:otherwise>
                                        </xsl:choose>

                                    </xsl:with-param>
                                </xsl:call-template>
                            </dd>
                            <!-- Display the contents of 'Description' only if bitstream contains a description -->
                            <xsl:if test="mets:FLocat[@LOCTYPE='URL']/@xlink:label != ''">
                                <dt>
                                    <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-description</i18n:text>
                                    <xsl:text>:</xsl:text>
                                </dt>
                                <dd class="word-break">
                                    <xsl:attribute name="title">
                                        <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:label"/>
                                    </xsl:attribute>
                                    <!--<xsl:value-of select="util:shortenString(mets:FLocat[@LOCTYPE='URL']/@xlink:label, 50, 5)"/>-->
                                    <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:label"/>
                                </dd>
                            </xsl:if>
                        </dl>
                    </div>

                    <div class="file-link col-xs-4">
                        <xsl:choose>
                            <xsl:when test="@ADMID">
                                <xsl:call-template name="display-rights"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="view-open"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </div>

                    <!-- Crude method of adding a little bit of space between file descriptions when there is no thumbnail present -->
                    <!--<div class="clearfix"></div>-->

                </xsl:otherwise>

            </xsl:choose>

        </div>

    </xsl:template>

    <xsl:template name="view-open">
        <a>
            <xsl:attribute name="href">
                <xsl:value-of select="mets:FLocat[@LOCTYPE='URL']/@xlink:href"/>
            </xsl:attribute>
            <i18n:text>xmlui.dri2xhtml.METS-1.0.item-files-viewOpen</i18n:text>
        </a>
    </xsl:template>

    <xsl:template name="display-rights">
        <xsl:variable name="file_id" select="jstring:replaceAll(jstring:replaceAll(string(@ADMID), '_METSRIGHTS', ''), 'rightsMD_', '')"/>
        <xsl:variable name="rights_declaration" select="../../../mets:amdSec/mets:rightsMD[@ID = concat('rightsMD_', $file_id, '_METSRIGHTS')]/mets:mdWrap/mets:xmlData/rights:RightsDeclarationMD"/>
        <xsl:variable name="rights_context" select="$rights_declaration/rights:Context"/>
        <xsl:variable name="users">
            <xsl:for-each select="$rights_declaration/*">
                <xsl:value-of select="rights:UserName"/>
                <xsl:choose>
                    <xsl:when test="rights:UserName/@USERTYPE = 'GROUP'">
                       <xsl:text> (group)</xsl:text>
                    </xsl:when>
                    <xsl:when test="rights:UserName/@USERTYPE = 'INDIVIDUAL'">
                       <xsl:text> (individual)</xsl:text>
                    </xsl:when>
                </xsl:choose>
                <xsl:if test="position() != last()">, </xsl:if>
            </xsl:for-each>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="not ($rights_context/@CONTEXTCLASS = 'GENERAL PUBLIC') and ($rights_context/rights:Permissions/@DISPLAY = 'true')">
                <a href="{mets:FLocat[@LOCTYPE='URL']/@xlink:href}">
                    <img width="64" height="64" src="{concat($theme-path,'/images/Crystal_Clear_action_lock3_64px.png')}" title="Read access available for {$users}"/>
                    <!-- icon source: http://commons.wikimedia.org/wiki/File:Crystal_Clear_action_lock3.png -->
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="view-open"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="getFileIcon">
        <xsl:param name="mimetype"/>
            <i aria-hidden="true">
                <xsl:attribute name="class">
                <xsl:text>glyphicon </xsl:text>
                <xsl:choose>
                    <xsl:when test="contains(mets:FLocat[@LOCTYPE='URL']/@xlink:href,'isAllowed=n')">
                        <xsl:text> glyphicon-lock</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> glyphicon-file</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                </xsl:attribute>
            </i>
        <xsl:text> </xsl:text>
    </xsl:template>

    <!-- Note:- this section deals with CC licenses for legacy items, that is to say, items that have the license stuff in files rather than in metadata. -->
    <xsl:template match="mets:fileGrp[@USE='CC-LICENSE']" mode="simple">
        <xsl:choose>
            <!-- Change for St A for legacy items - If a license_rdf file is present, which it should be, dig out and display a link to the CC website. This mimics the JSPUI behaviour. -->
            <xsl:when test="./mets:file/mets:FLocat[@xlink:title='license_rdf']">
                <xsl:variable name="ccLicenseRdf">
                    <xsl:text>cocoon:/</xsl:text>
                    <xsl:value-of select="./mets:file/mets:FLocat[@xlink:title='license_rdf']/@xlink:href"/>
                </xsl:variable>
                <li>
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="document($ccLicenseRdf)//cc:license/@rdf:resource" />
                        </xsl:attribute>
                        <img class="img-responsive">
                            <xsl:attribute name="src">
                                <xsl:value-of select="concat($theme-path,'/images/cc-ship.gif')"/>
                            </xsl:attribute>
                            <!-- "Why is this a hard coded value?!" I hear you cry. Because you can't put an i18n element inside an xsl:attribute element. Any suggestions welcome. Robin. -->
                            <xsl:attribute name="alt">Creative Commons</xsl:attribute>
                        </img>
                    </a>
                </li>
            </xsl:when>
            <xsl:otherwise>
                <li>
                    <a href="{mets:file/mets:FLocat[@xlink:title='license_text']/@xlink:href}">
                        <img class="img-responsive">
                            <xsl:attribute name="src">
                                <xsl:value-of select="concat($theme-path,'/images/cc-ship.gif')"/>
                            </xsl:attribute>
                            <!-- "Why is this a hard coded value?!" I hear you cry. Because you can't put an i18n element inside an xsl:attribute element. Any suggestions welcome. Robin. -->
                            <xsl:attribute name="alt">Creative Commons</xsl:attribute>
                        </img>
                    </a>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Generate the license information from the file section -->
    <xsl:template match="mets:fileGrp[@USE='LICENSE']" mode="simple">
        <li>
            <a href="{mets:file/mets:FLocat[@xlink:title='license.txt']/@xlink:href}"><i18n:text>xmlui.dri2xhtml.structural.link_original_license</i18n:text></a>
        </li>
    </xsl:template>

    <!--
    File Type Mapping template

    This maps format MIME Types to human friendly File Type descriptions.
    Essentially, it looks for a corresponding 'key' in your messages.xml of this
    format: xmlui.dri2xhtml.mimetype.{MIME Type}

    (e.g.) <message key="xmlui.dri2xhtml.mimetype.application/pdf">PDF</message>

    If a key is found, the translated value is displayed as the File Type (e.g. PDF)
    If a key is NOT found, the MIME Type is displayed by default (e.g. application/pdf)
    -->
    <xsl:template name="getFileTypeDesc">
        <xsl:param name="mimetype"/>

        <!--Build full key name for MIME type (format: xmlui.dri2xhtml.mimetype.{MIME type})-->
        <xsl:variable name="mimetype-key">xmlui.dri2xhtml.mimetype.<xsl:value-of select='$mimetype'/></xsl:variable>

        <!--Lookup the MIME Type's key in messages.xml language file.  If not found, just display MIME Type-->
        <i18n:text i18n:key="{$mimetype-key}"><xsl:value-of select="$mimetype"/></i18n:text>
    </xsl:template>

    <xsl:template name="formatdate">
        <xsl:param name="datestr" />
        <!-- input format yyyy-mm-dd or yyyy -->
        <!-- output format dd/mm/yyyy -->
        <xsl:variable name="dd">
            <xsl:value-of select="substring($datestr,9,2)" />
        </xsl:variable>
        <xsl:variable name="mm">
            <xsl:value-of select="substring($datestr,6,2)" />
        </xsl:variable>
        <xsl:variable name="yyyy">
            <xsl:value-of select="substring($datestr,1,4)" />
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length($datestr) &lt; 5">
                <xsl:value-of select="$yyyy" />
            </xsl:when>
            <xsl:when test="string-length($datestr) &lt; 8">
                <xsl:value-of select="$mm" />
                <xsl:value-of select="'/'" />
                <xsl:value-of select="$yyyy" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$dd" />
                <xsl:value-of select="'/'" />
                <xsl:value-of select="$mm" />
                <xsl:value-of select="'/'" />
                <xsl:value-of select="$yyyy" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


</xsl:stylesheet>
