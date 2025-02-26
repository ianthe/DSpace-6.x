<!--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

-->

<!--
    Main structure of the page, determines where
    header, footer, body, navigation are structurally rendered.
    Rendering of the header, footer, trail and alerts

    Author: art.lowel at atmire.com
    Author: lieven.droogmans at atmire.com
    Author: ben at atmire.com
    Author: Alexey Maslov

-->

<xsl:stylesheet xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
                xmlns:dri="http://di.tamu.edu/DRI/1.0/"
                xmlns:mets="http://www.loc.gov/METS/"
                xmlns:xlink="http://www.w3.org/TR/xlink/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:mods="http://www.loc.gov/mods/v3"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:confman="org.dspace.core.ConfigurationManager"
                exclude-result-prefixes="i18n dri mets xlink xsl dim xhtml mods dc confman">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <!--
        Requested Page URI. Some functions may alter behavior of processing depending if URI matches a pattern.
        Specifically, adding a static page will need to override the DRI, to directly add content.
    -->
    <xsl:variable name="request-uri" select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='URI']"/>

    <!--
        The starting point of any XSL processing is matching the root element. In DRI the root element is document,
        which contains a version attribute and three top level elements: body, options, meta (in that order).

        This template creates the html document, giving it a head and body. A title and the CSS style reference
        are placed in the html head, while the body is further split into several divs. The top-level div
        directly under html body is called "ds-main". It is further subdivided into:
            "ds-header"  - the header div containing title, subtitle, trail and other front matter
            "ds-body"    - the div containing all the content of the page; built from the contents of dri:body
            "ds-options" - the div with all the navigation and actions; built from the contents of dri:options
            "ds-footer"  - optional footer div, containing misc information

        The order in which the top level divisions appear may have some impact on the design of CSS and the
        final appearance of the DSpace page. While the layout of the DRI schema does favor the above div
        arrangement, nothing is preventing the designer from changing them around or adding new ones by
        overriding the dri:document template.
    -->
    <xsl:template match="dri:document">

        <xsl:choose>
            <xsl:when test="not($isModal)">


            <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html&gt;
            </xsl:text>
            <xsl:text disable-output-escaping="yes">&lt;!--[if lt IE 7]&gt; &lt;html class=&quot;no-js lt-ie9 lt-ie8 lt-ie7&quot; lang=&quot;en&quot;&gt; &lt;![endif]--&gt;
            &lt;!--[if IE 7]&gt;    &lt;html class=&quot;no-js lt-ie9 lt-ie8&quot; lang=&quot;en&quot;&gt; &lt;![endif]--&gt;
            &lt;!--[if IE 8]&gt;    &lt;html class=&quot;no-js lt-ie9&quot; lang=&quot;en&quot;&gt; &lt;![endif]--&gt;
            &lt;!--[if gt IE 8]&gt;&lt;!--&gt; &lt;html class=&quot;no-js&quot; lang=&quot;en&quot;&gt; &lt;!--&lt;![endif]--&gt;
            </xsl:text>

                <!-- First of all, build the HTML head element -->

                <xsl:call-template name="buildHead"/>

                <!-- Then proceed to the body -->
                <body>
                    <!-- Prompt IE 6 users to install Chrome Frame. Remove this if you support IE 6.
                   chromium.org/developers/how-tos/chrome-frame-getting-started -->
                    <!--[if lt IE 7]><p class=chromeframe>Your browser is <em>ancient!</em> <a href="http://browsehappy.com/">Upgrade to a different browser</a> or <a href="http://www.google.com/chromeframe/?redirect=true">install Google Chrome Frame</a> to experience this site.</p><![endif]-->
                    <xsl:choose>
                        <xsl:when
                                test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='framing'][@qualifier='popup']">
                            <xsl:apply-templates select="dri:body/*"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="buildHeader"/>
                            <!--<xsl:call-template name="buildTrail"/>-->
                            <!--javascript-disabled warning, will be invisible if javascript is enabled-->
                            <div id="no-js-warning-wrapper" class="hidden">
                                <div id="no-js-warning">
                                    <div class="notice failure">
                                        <xsl:text>JavaScript is disabled for your browser. Some features of this site may not work without it.</xsl:text>
                                    </div>
                                </div>
                            </div>

                            <div id="main-container" class="container">

                                <div class="row row-offcanvas row-offcanvas-right">
                                    <div class="horizontal-slider clearfix">
                                        <div class="col-xs-12 col-sm-12 col-md-9 main-content">
                                            <xsl:apply-templates select="*[not(self::dri:options)]"/>

                                            <!--<div class="visible-xs visible-sm">
                                                <xsl:call-template name="buildFooter"/>
                                            </div>-->
                                        </div>
                                        <div class="col-xs-6 col-sm-3 sidebar-offcanvas" id="sidebar" role="navigation">
                                            <xsl:apply-templates select="dri:options"/>
                                        </div>

                                    </div>
                                </div>

                            </div>
                            <div class="clearfix"></div>
                            <!--<div class="visible-xs visible-sm">
                                <xsl:call-template name="buildFooter"/>
                            </div>-->
                            <!--
                        The footer div, dropping whatever extra information is needed on the page. It will
                        most likely be something similar in structure to the currently given example. -->
                            <div class="visible-xs visible-sm visible-md visible-lg">
                                <xsl:call-template name="buildFooter"/>
                            </div>


                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- Javascript at the bottom for fast page loading -->
                    <xsl:call-template name="addJavascript"/>
                </body>
                <xsl:text disable-output-escaping="yes">&lt;/html&gt;</xsl:text>

            </xsl:when>
            <xsl:otherwise>
                <!-- This is only a starting point. If you want to use this feature you need to implement
                JavaScript code and a XSLT template by yourself. Currently this is used for the DSpace Value Lookup -->
                <xsl:apply-templates select="dri:body" mode="modal"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- The HTML head element contains references to CSS as well as embedded JavaScript code. Most of this
    information is either user-provided bits of post-processing (as in the case of the JavaScript), or
    references to stylesheets pulled directly from the pageMeta element. -->
    <xsl:template name="buildHead">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>

            <!-- Use the .htaccess and remove these lines to avoid edge case issues.
             More info: h5bp.com/i/378 -->
            <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>

            <!-- Mobile viewport optimized: h5bp.com/viewport -->
            <meta name="viewport" content="width=device-width,initial-scale=1"/>

            <link rel="shortcut icon">
                <xsl:attribute name="href">
                    <xsl:value-of select="$theme-path"/>
                    <xsl:text>images/sta-favicon.ico</xsl:text>
                </xsl:attribute>
            </link>
            <link rel="apple-touch-icon">
                <xsl:attribute name="href">
                    <xsl:value-of select="$theme-path"/>
                    <xsl:text>images/apple-touch-icon.png</xsl:text>
                </xsl:attribute>
            </link>

            <meta name="Generator">
                <xsl:attribute name="content">
                    <xsl:text>DSpace</xsl:text>
                    <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='dspace'][@qualifier='version']">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='dspace'][@qualifier='version']"/>
                    </xsl:if>
                </xsl:attribute>
            </meta>

            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='ROBOTS'][not(@qualifier)]">
                <meta name="ROBOTS">
                    <xsl:attribute name="content">
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='ROBOTS']"/>
                    </xsl:attribute>
                </meta>
            </xsl:if>

            <!-- Add stylesheets -->

            <!--TODO figure out a way to include these in the concat & minify-->
            <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='stylesheet']">
                <link rel="stylesheet" type="text/css">
                    <xsl:attribute name="media">
                        <xsl:value-of select="@qualifier"/>
                    </xsl:attribute>
                    <xsl:attribute name="href">
                        <xsl:value-of select="$theme-path"/>
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </link>
            </xsl:for-each>

            <link rel="stylesheet" href="{concat($theme-path, 'styles/main.css')}"/>

            <!-- Add syndication feeds -->
            <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='feed']">
                <link rel="alternate" type="application">
                    <xsl:attribute name="type">
                        <xsl:text>application/</xsl:text>
                        <xsl:value-of select="@qualifier"/>
                    </xsl:attribute>
                    <xsl:attribute name="href">
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </link>
            </xsl:for-each>

            <!--  Add OpenSearch auto-discovery link -->
            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='shortName']">
                <link rel="search" type="application/opensearchdescription+xml">
                    <xsl:attribute name="href">
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='scheme']"/>
                        <xsl:text>://</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='serverName']"/>
                        <xsl:text>:</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='serverPort']"/>
                        <xsl:value-of select="$context-path"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='autolink']"/>
                    </xsl:attribute>
                    <xsl:attribute name="title" >
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='shortName']"/>
                    </xsl:attribute>
                </link>
            </xsl:if>

            <!-- The following javascript removes the default text of empty text areas when they are focused on or submitted -->
            <!-- There is also javascript to disable submitting a form when the 'enter' key is pressed. -->
            <script>
                //Clear default text of empty text areas on focus
                function tFocus(element)
                {
                if (element.value == '<i18n:text>xmlui.dri2xhtml.default.textarea.value</i18n:text>'){element.value='';}
                }
                //Clear default text of empty text areas on submit
                function tSubmit(form)
                {
                var defaultedElements = document.getElementsByTagName("textarea");
                for (var i=0; i != defaultedElements.length; i++){
                if (defaultedElements[i].value == '<i18n:text>xmlui.dri2xhtml.default.textarea.value</i18n:text>'){
                defaultedElements[i].value='';}}
                }
                //Disable pressing 'enter' key to submit a form (otherwise pressing 'enter' causes a submission to start over)
                function disableEnterKey(e)
                {
                var key;

                if(window.event)
                key = window.event.keyCode;     //Internet Explorer
                else
                key = e.which;     //Firefox and Netscape

                if(key == 13)  //if "Enter" pressed, then disable!
                return false;
                else
                return true;
                }
            </script>

            <xsl:text disable-output-escaping="yes">&lt;!--[if lt IE 9]&gt;
                &lt;script src="</xsl:text><xsl:value-of select="concat($theme-path, 'vendor/html5shiv/dist/html5shiv.js')"/><xsl:text disable-output-escaping="yes">"&gt;&#160;&lt;/script&gt;
                &lt;script src="</xsl:text><xsl:value-of select="concat($theme-path, 'vendor/respond/dest/respond.min.js')"/><xsl:text disable-output-escaping="yes">"&gt;&#160;&lt;/script&gt;
                &lt;![endif]--&gt;</xsl:text>

            <!-- Modernizr enables HTML5 elements & feature detects -->
            <script src="{concat($theme-path, 'vendor/modernizr/modernizr.js')}">&#160;</script>

            <!-- Add the title in -->
            <xsl:variable name="page_title" select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='title'][last()]" />
            <title>
                <xsl:choose>
                    <xsl:when test="starts-with($request-uri, 'page/accessibility')">
                        Accessibility Statement
                    </xsl:when>
                    <xsl:when test="not($page_title)">
                        <xsl:text>  </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$page_title/node()" />
                    </xsl:otherwise>
                </xsl:choose>
            </title>

            <!-- Head metadata in item pages -->
            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='xhtml_head_item']">
                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='xhtml_head_item']"
                              disable-output-escaping="yes"/>
            </xsl:if>

            <!-- Add all Google Scholar Metadata values -->
            <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[substring(@element, 1, 9) = 'citation_']">
                <meta name="{@element}" content="{.}"></meta>
            </xsl:for-each>

            <!-- Add MathJAX JS library to render scientific formulas-->
            <xsl:if test="confman:getProperty('webui.browse.render-scientific-formulas') = 'true'">
                <script type="text/x-mathjax-config">
                    MathJax.Hub.Config({
                      tex2jax: {
                        ignoreClass: "detail-field-data|detailtable|exception"
                      },
                      TeX: {
                        Macros: {
                          AA: '{\\mathring A}'
                        }
                      }
                    });
                </script>
                <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS-MML_HTMLorMML">&#160;</script>
            </xsl:if>

            <!-- Add Altmetrics JS -->
            <script type='text/javascript' src='https://d1bxh8uas1mnw7.cloudfront.net/assets/embed.js'></script>
            <!--<script type='text/javascript'>
                $(function() 
                {
                    alert('test');
                    //if($('.altmetric-embed')[0].html() === ""){ $($('.altmetric-embed')[0]).parent().hide(); }
                    //if($('.altmetric-embed')[1].html() === ""){ $($('.altmetric-embed')[1]).parent().hide(); }
                });
            </script>-->

            <!-- CORE Recommender JS -->
            <!-- <script>
                (function (d, s, idScript, idRec, userInput) {
                    var coreAddress = 'https://core.ac.uk/';
                    var js, fjs = d.getElementsByTagName(s)[0];
                    if (d.getElementById(idScript)) return;
                    js = d.createElement(s);
                    js.id = idScript;
                    js.src = coreAddress + 'recommender/embed.js';
                    fjs.parentNode.insertBefore(js, fjs);

                    localStorage.setItem('idRecommender', idRec);
                    localStorage.setItem('userInput', JSON.stringify(userInput));

                    var link = d.createElement('link');
                    link.setAttribute('rel', 'stylesheet');
                    link.setAttribute('type', 'text/css');
                    link.setAttribute('href', coreAddress + 'recommender/embed-default-style.css');
                    d.getElementsByTagName('head')[0].appendChild(link);
                }(document, 'script', 'recommender-embed', 'fbca3d', {}));
            </script> -->

            <!-- Script to format e-these submission form text where it is unable in xml -->
            <script type="text/javascript">
                window.onload = function ()
                {
                    if(window.location.href.indexOf("10023/19869/submit/") > -1)
                    {
                        var plain_text = document.getElementsByClassName('bold-format');
                        if(plain_text.length > 0)
                        {
                            var bold_text = plain_text[0].textContent.split(". ");
                            plain_text[0].innerHTML = bold_text[0] + ". <b>" + bold_text[1] + "</b>";
                        }

                        var submission_complete = document.getElementById('aspect_submission_submit_CompletedStep_div_submit-complete');
                        if (submission_complete !== null)
                        {
                            var submission_div = document.getElementById('aspect_submission_submit_CompletedStep_div_submit-complete').children;

                            submission_div[5].outerHTML = "<li>" + submission_div[5].textContent + "</li>";
                            submission_div[6].outerHTML = "<li>" + submission_div[6].textContent + "</li>";
                            submission_div[7].outerHTML = "<li>" + submission_div[7].textContent + "</li>";
                            submission_div[8].outerHTML = "<li>" + submission_div[8].textContent + "</li>";
                            submission_div[5].style.marginLeft = "20px";
                            submission_div[6].style.marginLeft = "20px";
                            submission_div[7].style.marginLeft = "20px";
                            submission_div[8].style.marginLeft = "20px";
                            submission_div[8].style.marginBottom = "10px";
                        }

                    }

                    if(document.getElementById('aspect_workflow_RejectTaskStep_field_reason') !== null)
                    {
                        var textarea = "· We can't open your PDF to check the thesis full text. Please replace the PDF with a file that we can open\n· Signatures are not present in the declaration in your PDF. Please add the signatures and replace the PDF\n· Your declaration is not complete. Please complete the declaration and replace the PDF\n\n· The embargo in your declaration does not match the embargo that we have on record for your thesis. Please correct the embargo in your declaration and replace the PDF\n· The abstract is not included in the full text of your thesis. Please add the abstract and replace the PDF\n· The title page is not included in the full text of your thesis. Please add the title page and replace the PDF\n\nWe also have the following queries:\nInsert extra free text here if you want to use this section. Otherwise delete both lines in this free text section to remove this section completely from the email to the submitter";
                        document.getElementById('aspect_workflow_RejectTaskStep_field_reason').innerHTML = textarea;
                    }
                };
            </script>

        </head>
    </xsl:template>


    <!-- The header (distinct from the HTML head element) contains the title, subtitle, login box and various
        placeholders for header images -->
    <xsl:template name="buildHeader">


        <header class="sta-header">
            <div class="container sta-header-content">
                <div class="row">
                    <div class="col-xs-12 col-sm-8 col-md-9 sta-header-title">
                        <h1 class="sta-title">
                            <a href="{$context-path}/">
                                St Andrews Research Repository <span class="oblique"></span>
                            </a>
                        </h1>
                    </div>
                    <div class="col-sm-4 col-md-3 hidden-xs sta-header-logos">
                        <a href="//www.st-andrews.ac.uk" class="pull-right" title="St Andrews University Home">
                            <img src="{$theme-path}images/01-standard-black-text.png" alt="St Andrews University Home" />
                        </a>
                        <!--<a id="logo" href="//www.st-andrews.ac.uk/library/" class="pull-right" title="St Andrews University Library">
                            <img src="{$theme-path}images/sta-library-logo.png" alt="St Andrews University Library" />
                        </a>-->
                    </div>
                </div>

                <div class="clearfix"></div>
            </div>

            <div class="navbar navbar-default navbar-static-top" role="navigation">
                <div class="container sta-navbar">
                    <div class="col-xs-12 col-sm-12 col-md-12 sta-navbar-content">
                        <div class="navbar-header col-md-9">

                            <button type="button" class="navbar-toggle" data-toggle="offcanvas">
                                <span class="sr-only">
                                    <i18n:text>xmlui.mirage2.page-structure.toggleNavigation</i18n:text>
                                </span>
                                <span class="icon-bar"></span>
                                <span class="icon-bar"></span>
                                <span class="icon-bar"></span>
                            </button>
                            <!-- breadcrumbs -->
                            <div class="pull-left">
                                <xsl:choose>
                                    <xsl:when test="count(/dri:document/dri:meta/dri:pageMeta/dri:trail) > 1">
                                        <div class="breadcrumb dropdown visible-xs visible-sm">
                                            <a id="trail-dropdown-toggle" href="#" role="button" class="dropdown-toggle"
                                               data-toggle="dropdown">
                                                <xsl:variable name="last-node"
                                                              select="/dri:document/dri:meta/dri:pageMeta/dri:trail[last()]"/>
                                                <xsl:choose>
                                                    <xsl:when test="$last-node/i18n:*">
                                                        <xsl:apply-templates select="$last-node/*"/>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:apply-templates select="$last-node/text()"/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                                <xsl:text>&#160;</xsl:text>
                                                <b class="caret"/>
                                            </a>
                                            <ul class="dropdown-menu" role="menu" aria-labelledby="trail-dropdown-toggle">
                                                <xsl:apply-templates select="/dri:document/dri:meta/dri:pageMeta/dri:trail"
                                                                     mode="dropdown"/>
                                            </ul>
                                        </div>
                                        <div class="sta-lg-breadcrumb visible-lg hidden-md hidden-xs hidden-sm">
                                            <ul class="breadcrumb">
                                                <xsl:apply-templates select="/dri:document/dri:meta/dri:pageMeta/dri:trail"/>
                                            </ul>
                                        </div>
                                        <div class="sta-md-breadcrumb hidden-lg visible-md hidden-xs hidden-sm">
                                            <ul class="breadcrumb">
                                                <xsl:apply-templates select="/dri:document/dri:meta/dri:pageMeta/dri:trail"/>
                                            </ul>
                                        </div>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <ul class="breadcrumb">
                                            <xsl:apply-templates select="/dri:document/dri:meta/dri:pageMeta/dri:trail"/>
                                        </ul>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </div>
                            <!-- extra small screen size icons -->
                            <div class="navbar-header pull-right visible-xs hidden-sm hidden-md hidden-lg">
                                <ul class="nav nav-pills pull-right">
                                    <!--xsl:call-template name="languageSelection-xs"/-->

                                    <xsl:choose>
                                        <xsl:when test="/dri:document/dri:meta/dri:userMeta/@authenticated = 'yes'">
                                            <li class="dropdown">
                                                <button class="dropdown-toggle navbar-toggle navbar-link" id="user-dropdown-toggle-xs" href="#" role="button"  data-toggle="dropdown">
                                                    <b class="visible-xs glyphicon glyphicon-user" aria-hidden="true"/>
                                                </button>
                                                <ul class="dropdown-menu pull-right" role="menu" aria-labelledby="user-dropdown-toggle-xs" data-no-collapse="true">
                                                    <li>
                                                        <a href="{/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier' and @qualifier='url']}">
                                                            <i18n:text>xmlui.EPerson.Navigation.profile</i18n:text>
                                                        </a>
                                                    </li>
                                                    <li>
                                                        <a href="{/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier' and @qualifier='logoutURL']}">
                                                            <i18n:text>xmlui.dri2xhtml.structural.logout</i18n:text>
                                                        </a>
                                                    </li>
                                                </ul>
                                            </li>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <li>
                                                <form style="display: inline" action="{/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier' and @qualifier='loginURL']}" method="get">
                                                    <button class="navbar-toggle navbar-link">
                                                        <b class="visible-xs glyphicon glyphicon-user" aria-hidden="true"/>
                                                    </button>
                                                </form>
                                            </li>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </ul>
                            </div>
                        </div>
                        <!-- all but extra small screen size dropdown -->
                        <div class="navbar-header pull-right hidden-xs">
                            <button data-toggle="offcanvas" class="navbar-toggle visible-sm" type="button">
                                <span class="sr-only"><i18n:text>xmlui.mirage2.page-structure.toggleNavigation</i18n:text></span>
                                <span class="icon-bar"></span>
                                <span class="icon-bar"></span>
                                <span class="icon-bar"></span>
                            </button>
                            <!--ul class="nav navbar-nav pull-right">
                                <xsl:call-template name="languageSelection"/>
                            </ul-->
                            <ul class="nav navbar-nav pull-right sta-lg-dropdown">
                                <xsl:choose>
                                    <xsl:when test="/dri:document/dri:meta/dri:userMeta/@authenticated = 'yes'">
                                        <li class="dropdown">
                                            <a id="user-dropdown-toggle" href="#" role="button" class="dropdown-toggle"
                                               data-toggle="dropdown">
                                                <span class="hidden-xs">
                                                    <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier' and @qualifier='firstName']"/>
                                                    <xsl:text> </xsl:text>
                                                    <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier' and @qualifier='lastName']"/>
                                                    &#160;
                                                    <b class="caret"/>
                                                </span>
                                            </a>
                                            <ul class="dropdown-menu pull-right" role="menu" aria-labelledby="user-dropdown-toggle" data-no-collapse="true">
                                                <li>
                                                    <a href="{/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier' and @qualifier='url']}">
                                                        <i18n:text>xmlui.EPerson.Navigation.profile</i18n:text>
                                                    </a>
                                                </li>
                                                <li>
                                                    <a href="{/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier' and @qualifier='logoutURL']}">
                                                        <i18n:text>xmlui.dri2xhtml.structural.logout</i18n:text>
                                                    </a>
                                                </li>
                                            </ul>
                                        </li>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <li>
                                            <a href="{/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier' and @qualifier='loginURL']}">
                                                <span class="hidden-xs">
                                                    <i18n:text>xmlui.dri2xhtml.structural.login</i18n:text>
                                                </span>
                                            </a>
                                        </li>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </ul>

                        </div>
                    </div>
                </div>
            </div>

        </header>

    </xsl:template>


    <!-- The header (distinct from the HTML head element) contains the title, subtitle, login box and various
        placeholders for header images -->
    <xsl:template name="buildTrail">
        <div class="trail-wrapper hidden-print">
            <div class="container">
                <div class="row">
                    <!--TODO-->
                    <div class="col-xs-12">
                        <xsl:choose>
                            <xsl:when test="count(/dri:document/dri:meta/dri:pageMeta/dri:trail) > 1">
                                <div class="breadcrumb dropdown visible-xs visible-sm">
                                    <a id="trail-dropdown-toggle" href="#" role="button" class="dropdown-toggle"
                                       data-toggle="dropdown">
                                        <xsl:variable name="last-node"
                                                      select="/dri:document/dri:meta/dri:pageMeta/dri:trail[last()]"/>
                                        <xsl:choose>
                                            <xsl:when test="$last-node/i18n:*">
                                                <xsl:apply-templates select="$last-node/*"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:apply-templates select="$last-node/text()"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        <xsl:text>&#160;</xsl:text>
                                        <b class="caret"/>
                                    </a>
                                    <ul class="dropdown-menu" role="menu" aria-labelledby="trail-dropdown-toggle">
                                        <xsl:apply-templates select="/dri:document/dri:meta/dri:pageMeta/dri:trail"
                                                             mode="dropdown"/>
                                    </ul>
                                </div>
                                <ul class="breadcrumb hidden-xs hidden-sm">
                                    <xsl:apply-templates select="/dri:document/dri:meta/dri:pageMeta/dri:trail"/>
                                </ul>
                            </xsl:when>
                            <xsl:otherwise>
                                <ul class="breadcrumb">
                                    <xsl:apply-templates select="/dri:document/dri:meta/dri:pageMeta/dri:trail"/>
                                </ul>
                            </xsl:otherwise>
                        </xsl:choose>
                    </div>
                </div>
            </div>
        </div>


    </xsl:template>

    <!--The Trail-->
    <xsl:template match="dri:trail">
        <!--put an arrow between the parts of the trail-->
        <li>
            <xsl:if test="position()=1">
                <i class="glyphicon glyphicon-home" aria-hidden="true"/>&#160;
            </xsl:if>
            <!-- Determine whether we are dealing with a link or plain text trail link -->
            <xsl:choose>
                <xsl:when test="./@target">
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="./@target"/>
                        </xsl:attribute>
                        <xsl:apply-templates />
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="class">active</xsl:attribute>
                    <xsl:apply-templates />
                </xsl:otherwise>
            </xsl:choose>
        </li>
    </xsl:template>

    <xsl:template match="dri:trail" mode="dropdown">
        <!--put an arrow between the parts of the trail-->
        <li role="presentation">
            <!-- Determine whether we are dealing with a link or plain text trail link -->
            <xsl:choose>
                <xsl:when test="./@target">
                    <a role="menuitem">
                        <xsl:attribute name="href">
                            <xsl:value-of select="./@target"/>
                        </xsl:attribute>
                        <xsl:if test="position()=1">
                            <i class="glyphicon glyphicon-home" aria-hidden="true"/>&#160;
                        </xsl:if>
                        <xsl:apply-templates />
                    </a>
                </xsl:when>
                <xsl:when test="position() > 1 and position() = last()">
                    <xsl:attribute name="class">disabled</xsl:attribute>
                    <a role="menuitem" href="#">
                        <xsl:apply-templates />
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="class">active</xsl:attribute>
                    <xsl:if test="position()=1">
                        <i class="glyphicon glyphicon-home" aria-hidden="true"/>&#160;
                    </xsl:if>
                    <xsl:apply-templates />
                </xsl:otherwise>
            </xsl:choose>
        </li>
    </xsl:template>

    <!--The License-->
    <xsl:template name="cc-license">
        <xsl:param name="metadataURL"/>
        <xsl:variable name="externalMetadataURL">
            <xsl:text>cocoon:/</xsl:text>
            <xsl:value-of select="$metadataURL"/>
            <xsl:text>?sections=dmdSec,fileSec&amp;fileGrpTypes=THUMBNAIL</xsl:text>
        </xsl:variable>

        <xsl:variable name="ccLicenseName"
                      select="document($externalMetadataURL)//dim:field[@element='rights' and contains(., 'Attribution')]"
                />
        <xsl:variable name="ccLicenseUri"
                      select="document($externalMetadataURL)//dim:field[@element='rights'][@qualifier='uri']"
                />
        <xsl:variable name="handleUri">
            <xsl:for-each select="document($externalMetadataURL)//dim:field[@element='identifier' and @qualifier='uri']">
                <a>
                    <xsl:attribute name="href">
                        <xsl:copy-of select="./node()"/>
                    </xsl:attribute>
                    <xsl:copy-of select="./node()"/>
                </a>
                <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='uri']) != 0">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>

        <xsl:if test="$ccLicenseName and $ccLicenseUri and contains($ccLicenseUri, 'creativecommons')">
            <div about="{$handleUri}" class="row cc-license-new">
                <div class="col-sm-3 col-xs-12">
                    <a rel="license"
                       href="{$ccLicenseUri}"
                       alt="{$ccLicenseName}"
                       title="{$ccLicenseName}">
                        <img class="img-responsive">
                            <xsl:attribute name="src">
                                <xsl:value-of select="concat($theme-path,'/images/cc-ship.gif')"/>
                            </xsl:attribute>
                            <xsl:attribute name="alt">
                                <xsl:value-of select="$ccLicenseName"/>
                            </xsl:attribute>
                        </img>
                    </a>
                </div> <div class="col-sm-8">
                <span>
                    <i18n:text>xmlui.dri2xhtml.METS-1.0.cc-license-text</i18n:text>
                    <xsl:value-of select="$ccLicenseName"/>
                </span>
            </div>
            </div>
        </xsl:if>

        <div class="item-view-copyright item-page-field-wrapper table">
            <p>
                <i18n:text>xmlui.mirage2.itemSummaryView.Copyright</i18n:text>
            </p>
        </div>

    </xsl:template>

    <xsl:template name="cc-logo">
        <xsl:param name="ccLicenseName"/>
        <xsl:param name="ccLicenseUri"/>
        <xsl:variable name="ccLogo">
             <xsl:choose>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by/')">
                       <xsl:value-of select="'cc-by.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by-sa/')">
                       <xsl:value-of select="'cc-by-sa.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by-nd/')">
                       <xsl:value-of select="'cc-by-nd.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by-nc/')">
                       <xsl:value-of select="'cc-by-nc.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by-nc-sa/')">
                       <xsl:value-of select="'cc-by-nc-sa.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by-nc-nd/')">
                       <xsl:value-of select="'cc-by-nc-nd.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/publicdomain/zero/')">
                       <xsl:value-of select="'cc-zero.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/publicdomain/mark/')">
                       <xsl:value-of select="'cc-mark.png'" />
                  </xsl:when>
                  <xsl:otherwise>
                       <xsl:value-of select="'cc-generic.png'" />
                  </xsl:otherwise>
             </xsl:choose>
        </xsl:variable>
        <img class="img-responsive">
             <xsl:attribute name="src">
                <xsl:value-of select="concat($theme-path,'/images/creativecommons/', $ccLogo)"/>
             </xsl:attribute>
             <xsl:attribute name="alt">
                 <xsl:value-of select="$ccLicenseName"/>
             </xsl:attribute>
        </img>
    </xsl:template>

    <!-- Like the header, the footer contains various miscellaneous text, links, and image placeholders -->
    <xsl:template name="buildFooter">
        <footer class="sta-footer">
            <div class="sta-footer-top-content">
            <div class="container">
                <div class="row sta-footer-top">
                    <div class="col-md-3 footer-block">
                        <h3>Open Access</h3>

                        <p>To find out how you can benefit from open access to research, see our <a href="//www.st-andrews.ac.uk/library/services/researchsupport/openaccess/" title="University of St Andrews Library Open Access web pages" target="_blank">library web pages</a> and <a href="//univstandrews-oaresearch.blogspot.co.uk/" title="Open Access Blog" target="_blank">Open Access blog</a>. For open access help contact: <a href="mailto:openaccess@st-andrews.ac.uk">openaccess@st-andrews.ac.uk</a>.</p>
                        <h3>Accessibility</h3>
                        <p>Read our <a href="/page/accessibility" title="Accessibility statement">Accessibility statement</a>.</p>
                        </div>
                    <div class="col-md-3 footer-block">
                        <h3>How to submit research papers</h3>
                        <p>The full text of research papers can be submitted to the repository via <a href="//www.st-andrews.ac.uk/staff/research/pure/" title="Pure" target="_blank">Pure</a>, the University's research information system. For help see our guide: <a href="http://www.st-andrews.ac.uk/library/services/researchsupport/openaccess/deposit/" title="How to deposit in Pure" target="_blank">How to deposit in Pure</a>.</p>
                    </div>
                    <div class="col-md-3 footer-block">
                        <h3>Electronic thesis deposit</h3>
                        <p>Help with <a href="https://libguides.st-andrews.ac.uk/c.php?g=669998&amp;p=4756152" target="_blank" title="Help with electronic theses deposit">deposit</a>.</p>
                        <h3>Repository help</h3>
                        <p>For repository help contact: <a href="mailto:Digital-Repository@st-andrews.ac.uk" title="Email address for St Andrews Research Repository">Digital-Repository@st-andrews.ac.uk</a>.</p>
                        <p><a href="/feedback" title="For sharing feedback about the St Andrews Research Repository">Give Feedback</a></p>
                    </div>
                    <div class="col-md-3 footer-block">
                        <h3>Cookie policy</h3>
                        <p>This site may use cookies. Please see <a href="//www.st-andrews.ac.uk/terms/" target="_blank" title="Terms and Conditions">Terms and Conditions</a>.</p>
                        <h3>Usage statistics</h3>
                        <p>COUNTER-compliant statistics on downloads from the repository are available from the <a href="http://irus.mimas.ac.uk/" title="IRUS-UK Service">IRUS-UK Service</a>. <a href="mailto:openaccess@st-andrews.ac.uk?subject=Enquiry%20about%20IRUS-UK%20statistics" title="Email an enquiry about IRUS-UK statistics">Contact us</a> for information.</p>
                    </div>

                </div>
            </div>
            </div>
            <div class="sta-footer-bottom-content">
            <div class="container">
            <div class="row sta-footer-bottom">
                <div class="col-md-9">
                    <p id="footer-copyright"><xsl:text>&#169;</xsl:text> University of St Andrews Library</p>
                    <p id="footer-charity">University of St Andrews is a charity registered in Scotland, No SC013532.</p>
                </div>
                <div class="col-md-3">
                    <ul id="social">
                        <li>
                            <a href="https://www.facebook.com/uniofsta" target="_blank">
                                <img style="width : -1px; height : -1px; border : ; padding : ; margin : ; float : ;" alt="Facebook" src="{$theme-path}images/facebook-logo-svg.svg" />
                            </a>
                        </li>
                        <li>
                            <a href="https://twitter.com/univofstandrews/" target="_blank">
                                <img style="width : -1px; height : -1px; border : ; padding : ; margin : ; float : ;" alt="Twitter" src="{$theme-path}images/twitter-logo-svg.svg" />
                            </a>
                        </li>
                    </ul>

                    </div>
                </div>
                <!--Invisible link to HTML sitemap (for search engines) -->
                <a class="hidden">
                    <xsl:attribute name="href">
                        <xsl:value-of
                                select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                        <xsl:text>/htmlmap</xsl:text>
                    </xsl:attribute>
                    <xsl:text>&#160;</xsl:text>
                </a>
            </div>
            </div>
        </footer>
    </xsl:template>


    <!--
            The meta, body, options elements; the three top-level elements in the schema
    -->




    <!--
        The template to handle the dri:body element. It simply creates the ds-body div and applies
        templates of the body's child elements (which consists entirely of dri:div tags).
    -->
    <xsl:template match="dri:body">
        <div>
            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='alert'][@qualifier='message']">
                <div class="alert alert-warning">
                    <button type="button" class="close" data-dismiss="alert">&#215;</button>
                    <xsl:copy-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='alert'][@qualifier='message']/node()"/>
                </div>
            </xsl:if>

            <!-- Check for the custom pages -->
            <xsl:choose>
                <xsl:when test="starts-with($request-uri, 'page/accessibility')">
                    <div class="hero-unit">
                        <h1 id="d.en.106512" class="page-heading">Accessibility statement for the Research repository</h1>
                        <div id="d.en.106513">
                            <p>This statement applies to content published on the <a href="https://research-repository.st-andrews.ac.uk">https://research-repository.st-andrews.ac.uk</a> domain, run by the University of St Andrews. It does not apply to content on any other st-andrews.ac.uk domain or subdomains.</p>
                            <p>We want as many people as possible to be able to use this website. For example, that means you should be able to:</p>
                            <ul>
                                <li>change colours, contrast levels and fonts</li>
                                <li>zoom in up to 300% without the text spilling off the screen</li>
                                <li>navigate most of the website using just a keyboard</li>
                                <li>navigate most of the website using speech recognition software</li>
                                <li>listen to most of the website using a screen reader (including the most recent versions of JAWS, NVDA and VoiceOver).</li>
                            </ul>
                            <p>We’ve also made the website text as simple as possible to understand.</p>
                            <p><a href="https://mcmw.abilitynet.org.uk/">AbilityNet</a> has advice on making your device easier to use if you have a disability.</p>
                            <p>You can also explore some of our recommendations for tools that can <a href="https://www.st-andrews.ac.uk/students/advice/disabilities/student-study-toolkit/">make your online experience better</a>.</p>
                        </div>
                        <div id="d.en.106514">
                            <h2>How accessible this website is</h2>
                            <p>The Research Repository is currently not fully compliant with accessibility legislation. We are working with the software supplier and website host, Edinburgh University, to fix the issues. </p>
                            <p>Some areas of inaccessibility include:</p>
                            <ul>
                                <li>Some pages have poor colour contrast.</li>
                                <li>Some of our online forms are missing descriptions for screen readers.</li>
                                <li>Some links are only identifiable by colour.</li>
                                <li>Some link text is used to go to multiple destinations.</li>
                                <li>Some form elements are not grouped, making keyboard navigation harder.</li>
                                <li>Some metadata elements have an invalid language.</li>
                            </ul>
                        </div>
                        <div id="d.en.106515">
                            <h2>Feedback and contact information</h2>
                            <p>If you need information on this website in a different format like accessible PDF, large print, easy read, audio recording or braille:</p>
                            <ul>
                                <li>email: <a href="mailto:itservicedesk@st-andrews.ac.uk">itservicedesk@st-andrews.ac.uk</a> </li>
                                <li>phone: +44 (0)1334 46 3333</li>
                            </ul>
                        </div>
                        <div id="d.en.106516">
                            <h2>Reporting accessibility problems with this website</h2>
                            <p>We’re always looking to improve the accessibility of this website. If you find any problems that aren’t listed on this page or think we’re not meeting accessibility requirements, contact IT Service Desk:</p>
                            <ul>
                                <li>email: <a href="mailto:itservicedesk@st-andrews.ac.uk">itservicedesk@st-andrews.ac.uk</a></li>
                                <li>phone: +44 (0)1334 46 3333</li>
                            </ul>
                        </div>
                        <div id="d.en.106517">
                            <h2>Enforcement procedure</h2>
                            <p>The Equality and Human Rights Commission (EHRC) is responsible for enforcing the Public Sector Bodies (Websites and Mobile Applications) (No. 2) Accessibility Regulations 2018 (the ‘accessibility regulations’). If you’re not happy with how we respond to your complaint, contact the <a href="https://www.equalityadvisoryservice.com/">Equality Advisory and Support Service (EASS)</a>.</p>
                        </div>
                        <div id="d.en.106518">
                            <h2>Contacting us by phone or visiting us in person</h2>
                            <p>We have induction loops in main lecture venues, and we have portable loops that may be set up if requested in advance. We also have a Roger pen to assist visitors who use hearing aids.</p>
                            <p>We can provide a text relay service for people who are Deaf, deaf, hearing impaired or have a speech impediment who are contacting us by phone.</p>
                            <p>British Sign Language (BSL) users can contact us via the online BSL Video Relay Interpreting service from <a href="https://contactscotland-bsl.org/">Contact Scotland BSL</a>. We will also endeavour to arrange a BSL interpreter for visiting individuals that need that support, but this should be requested in advance as availability is limited.</p>
                            <p>Find out how to <a href="https://www.st-andrews.ac.uk/contact/">contact the University</a>. </p>
                        </div>
                        <div id="d.en.106519">
                            <h2>Technical information about this website’s accessibility</h2>
                            <p>The University of St Andrews is committed to making its website accessible, in accordance with the Public Sector Bodies (Websites and Mobile Applications) (No. 2) Accessibility Regulations 2018.</p>
                            <h2>Compliance status</h2>
                            <p>This website is partially compliant with the <a href="https://www.w3.org/TR/WCAG21/">Web Content Accessibility Guidelines (WCAG) version 2.1</a> AA standard due to the non-compliances and exemptions listed below.</p>
                        </div>
                        <div id="d.en.106520">
                            <h2>Non-accessible content</h2>
                            <h4>Forms and interactive elements</h4>
                            <p>There are forms and interactive elements such as carousels which do not meet multiple AA success criteria. We are working with the software supplier, Edinburgh University, to fix these issues,  including, but not limited to:</p>
                            <ul>
                                <li>Orientation (1.3.4)</li>
                                <li>Colour contrast (1.4.3)</li>
                                <li>Resize text (1.4.4)</li>
                                <li>Reflow (1.4.10)</li>
                                <li>Non-text contrast (1.4.11)</li>
                                <li>Text spacing (1.4.12)</li>
                                <li>Headings and labels (2.4.6)</li>
                                <li>Focus visible (2.4.7)</li>
                                <li>Consistent navigation (3.2.3)</li>
                                <li>Error suggestion (3.3.3)</li>
                                <li>Grouping (1.3.1)</li>
                            </ul>
                            <h4>Contrast Issues</h4>
                            <p>Some pages contain elements with low contrast between the element and its background. This can cause text to be difficult to read, especially for those with low vision, poor eyesight, or colour blindness (Success criterion 1.4.3 Contrast - minimum).</p>
                            <p>We are working with the software supplier, Edinburgh University, to fix this issue.</p>
                            <h4>Issues with focus indicator</h4>
                            <p>Some elements may not always display effective focus indication when interacting with elements (Success criterion 2.4.7 Focus visible).</p>
                            <p>We are working with the software supplier, Edinburgh University, to fix this issue.</p>
                            <h4>Link text used for multiple different destinations</h4>
                            <p>The same link text is used for links going to different destinations. Users might not know the difference if they are not somehow explained (Success criterion 2.4.4 Link Purpose (In Context)).</p>
                            <p>We are working with the software supplier, Edinburgh University, to fix this issue. </p>
                            <h4>Incorrect or missing labels</h4>
                            <p>There are some label and aria-labelledby tags that are not referencing the correct field. There are also some missing labels. This fails success criterium 1.1.1 Non-text Content.</p>
                            <p>We are working with the software supplier, Edinburgh University, to fix this issue.</p>
                            <h4>Input field has no description</h4>
                            <p>Input fields should always have a description that is explicitly associated with the field to make sure that users of assistive technologies will also know what the field is for. The Research Repository site has multiple IDs with the same value, failing criterium 1.3.1 Info and Relationships.</p>
                            <p>We are working with the software supplier, Edinburgh University, to fix this issue.</p>
                            <h4 class="media-content">Metadata language</h4>
                            <p>The value for the language attribute is not set to a valid language code for use in metadata on a record page.</p>
                            <p>We are working with the software supplier, Edinburgh University, to fix this issue.</p>
                        </div>
                        <div id="d.en.106521">
                            <h2>What we’re doing to improve accessibility</h2>
                            <p>We recognise that some content on Research Repository is not fully accessible, but the University is committed to improving this through:</p>
                            <ul>
                                <li>Working with the software supplier, Edinburgh University, on ensuring full compliance.</li>
                            </ul>
                        </div>
                        <div id="d.en.106522">
                            <h2>Preparation of this accessibility statement</h2>
                            <p>This statement was prepared on Monday 04 October 2021. It was last reviewed on Monday 04 October 2021.</p>
                            <p>Research Repository is tested on a regular basis, using accessibility tool provided by Siteimprove. This tool tests a sample of web pages and provides a report on accessibility issues. </p>
                            <p>Issues are prioritised according to the severity of the impact it may cause, the number of people that may be impacted and the time involved in resolving the issue.</p>
                        </div>
                    </div>
                </xsl:when>
                <!-- Otherwise use default handling of body -->
                <xsl:otherwise>
                    <xsl:apply-templates />
                </xsl:otherwise>
            </xsl:choose>

        </div>
    </xsl:template>


    <!-- Currently the dri:meta element is not parsed directly. Instead, parts of it are referenced from inside
        other elements (like reference). The blank template below ends the execution of the meta branch -->
    <xsl:template match="dri:meta">
    </xsl:template>

    <!-- Meta's children: userMeta, pageMeta, objectMeta and repositoryMeta may or may not have templates of
        their own. This depends on the meta template implementation, which currently does not go this deep.
    <xsl:template match="dri:userMeta" />
    <xsl:template match="dri:pageMeta" />
    <xsl:template match="dri:objectMeta" />
    <xsl:template match="dri:repositoryMeta" />
    -->

    <xsl:template name="addJavascript">

        <script type="text/javascript"><xsl:text>
                         if(typeof window.publication === 'undefined'){
                            window.publication={};
                          };
                        window.publication.contextPath= '</xsl:text><xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/><xsl:text>';</xsl:text>
            <xsl:text>window.publication.themePath= '</xsl:text><xsl:value-of select="$theme-path"/><xsl:text>';</xsl:text>
        </script>
        <!--TODO concat & minify!-->

        <script>
            <xsl:text>if(!window.DSpace){window.DSpace={};}window.DSpace.context_path='</xsl:text><xsl:value-of select="$context-path"/><xsl:text>';window.DSpace.theme_path='</xsl:text><xsl:value-of select="$theme-path"/><xsl:text>';</xsl:text>
        </script>

        <!--inject scripts.html containing all the theme specific javascript references
        that can be minified and concatinated in to a single file or separate and untouched
        depending on whether or not the developer maven profile was active-->
        <xsl:variable name="scriptURL">
            <xsl:text>cocoon://themes/</xsl:text>
            <!--we can't use $theme-path, because that contains the context path,
            and cocoon:// urls don't need the context path-->
            <xsl:value-of select="$pagemeta/dri:metadata[@element='theme'][@qualifier='path']"/>
            <xsl:text>scripts-dist.xml</xsl:text>
        </xsl:variable>
        <xsl:for-each select="document($scriptURL)/scripts/script">
            <script src="{$theme-path}{@src}">&#160;</script>
        </xsl:for-each>

        <!-- Add javascript specified in DRI -->
        <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][not(@qualifier)]">
            <script>
                <xsl:attribute name="src">
                    <xsl:value-of select="$theme-path"/>
                    <xsl:value-of select="."/>
                </xsl:attribute>&#160;</script>
        </xsl:for-each>

        <!-- add "shared" javascript from static, path is relative to webapp root-->
        <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][@qualifier='static']">
            <!--This is a dirty way of keeping the scriptaculous stuff from choice-support
            out of our theme without modifying the administrative and submission sitemaps.
            This is obviously not ideal, but adding those scripts in those sitemaps is far
            from ideal as well-->
            <xsl:choose>
                <xsl:when test="text() = 'static/js/choice-support.js'">
                    <script>
                        <xsl:attribute name="src">
                            <xsl:value-of select="$theme-path"/>
                            <xsl:text>js/choice-support.js</xsl:text>
                        </xsl:attribute>&#160;</script>
                </xsl:when>
                <xsl:when test="not(starts-with(text(), 'static/js/scriptaculous'))">
                    <script>
                        <xsl:attribute name="src">
                            <xsl:value-of
                                    select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                            <xsl:text>/</xsl:text>
                            <xsl:value-of select="."/>
                        </xsl:attribute>&#160;</script>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>

        <!-- add setup JS code if this is a choices lookup page -->
        <xsl:if test="dri:body/dri:div[@n='lookup']">
            <xsl:call-template name="choiceLookupPopUpSetup"/>
        </xsl:if>

        <xsl:call-template name="addJavascript-google-analytics" />
    </xsl:template>

    <xsl:template name="addJavascript-google-analytics">
        <!-- Add a google analytics script if the key is present -->
        <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']">
            <script><xsl:text>
                (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
                (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
                m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
                })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

                ga('create', '</xsl:text><xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']"/><xsl:text>', '</xsl:text><xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='serverName']"/><xsl:text>');
                ga('send', 'pageview');
            </xsl:text></script>
        </xsl:if>

        <script>
            <xsl:text>
                $(function() 
                {
                    if($('.altmet-handle').html() === ""){ $('.altmet-handle-head').hide(); }
                    if($('.altmet-doi').html() === ""){ $('.altmet-doi-head').hide(); }
                });
            </xsl:text>
        </script>

    </xsl:template>

    <!--The Language Selection
        Uses a page metadata curRequestURI which was introduced by in /xmlui-mirage2/src/main/webapp/themes/Mirage2/sitemap.xmap-->
    <xsl:template name="languageSelection">
        <xsl:variable name="curRequestURI">
            <xsl:value-of select="substring-after(/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='curRequestURI'],/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='URI'])"/>
        </xsl:variable>

        <xsl:if test="count(/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='page'][@qualifier='supportedLocale']) &gt; 1">
            <li id="ds-language-selection" class="dropdown">
                <xsl:variable name="active-locale" select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='page'][@qualifier='currentLocale']"/>
                <a id="language-dropdown-toggle" href="#" role="button" class="dropdown-toggle" data-toggle="dropdown">
                    <span class="hidden-xs">
                        <xsl:value-of
                                select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='supportedLocale'][@qualifier=$active-locale]"/>
                        <xsl:text>&#160;</xsl:text>
                        <b class="caret"/>
                    </span>
                </a>
                <ul class="dropdown-menu pull-right" role="menu" aria-labelledby="language-dropdown-toggle" data-no-collapse="true">
                    <xsl:for-each
                            select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='page'][@qualifier='supportedLocale']">
                        <xsl:variable name="locale" select="."/>
                        <li role="presentation">
                            <xsl:if test="$locale = $active-locale">
                                <xsl:attribute name="class">
                                    <xsl:text>disabled</xsl:text>
                                </xsl:attribute>
                            </xsl:if>
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$curRequestURI"/>
                                    <xsl:call-template name="getLanguageURL"/>
                                    <xsl:value-of select="$locale"/>
                                </xsl:attribute>
                                <xsl:value-of
                                        select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='supportedLocale'][@qualifier=$locale]"/>
                            </a>
                        </li>
                    </xsl:for-each>
                </ul>
            </li>
        </xsl:if>
    </xsl:template>

    <!-- Builds the Query String part of the language URL. If there already is an existing query string
like: ?filtertype=subject&filter_relational_operator=equals&filter=keyword1 it appends the locale parameter with the ampersand (&) symbol -->
    <xsl:template name="getLanguageURL">
        <xsl:variable name="queryString" select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='queryString']"/>
        <xsl:choose>
            <!-- There allready is a query string so append it and the language argument -->
            <xsl:when test="$queryString != ''">
                <xsl:text>?</xsl:text>
                <xsl:choose>
                    <xsl:when test="contains($queryString, '&amp;locale-attribute')">
                        <xsl:value-of select="substring-before($queryString, '&amp;locale-attribute')"/>
                        <xsl:text>&amp;locale-attribute=</xsl:text>
                    </xsl:when>
                    <!-- the query string is only the locale-attribute so remove it to append the correct one -->
                    <xsl:when test="starts-with($queryString, 'locale-attribute')">
                        <xsl:text>locale-attribute=</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$queryString"/>
                        <xsl:text>&amp;locale-attribute=</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>?locale-attribute=</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
