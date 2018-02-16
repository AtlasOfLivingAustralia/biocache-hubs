<g:set var="orgNameLong" value="${grailsApplication.config.skin.orgNameLong}"/>
<g:set var="orgNameShort" value="${grailsApplication.config.skin.orgNameShort}"/>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="shortcut icon" type="image/x-icon" href="favicon.ico">

    <title><g:layoutTitle /></title>
    <g:render template="/layouts/global"/>

    <asset:javascript src="jquery_migration.js"/>
    <asset:javascript src="bootstrap/js/bootstrap.js"/>
    <asset:javascript src="hubCore.js"/>

    <asset:stylesheet src="bootstrap/css/bootstrap.css" />
    <asset:stylesheet src="hubCore.css" />
    <asset:stylesheet src="generic.css" />

    <asset:script type="text/javascript">
        // initialise plugins
        jQuery(function(){
            // autocomplete on navbar search input
            jQuery("form#search-form-2011 input#search-2011, form#search-inpage input#search, input#search-2013").autocomplete('http://bie.ala.org.au/search/auto.jsonp', {
                extraParams: {limit: 100},
                dataType: 'jsonp',
                parse: function(data) {
                    var rows = new Array();
                    data = data.autoCompleteList;
                    for(var i=0; i<data.length; i++) {
                        rows[i] = {
                            data:data[i],
                            value: data[i].matchedNames[0],
                            result: data[i].matchedNames[0]
                        };
                    }
                    return rows;
                },
                matchSubset: false,
                formatItem: function(row, i, n) {
                    return row.matchedNames[0];
                },
                cacheLength: 10,
                minChars: 3,
                scroll: false,
                max: 10,
                selectFirst: false
            });

            // Mobile/desktop toggle
            // TODO: set a cookie so user's choice is remembered across pages
            var responsiveCssFile = $("#responsiveCss").attr("href"); // remember set href
            $(".toggleResponsive").click(function(e) {
                e.preventDefault();
                $(this).find("i").toggleClass("icon-resize-small icon-resize-full");
                var currentHref = $("#responsiveCss").attr("href");
                if (currentHref) {
                    $("#responsiveCss").attr("href", ""); // set to desktop (fixed)
                    $(this).find("span").html("Mobile");
                } else {
                    $("#responsiveCss").attr("href", responsiveCssFile); // set to mobile (responsive)
                    $(this).find("span").html("Desktop");
                }
            });

            $('.helphover').popover({animation: true, trigger:'hover'});
        });
    </asset:script>
    <g:layoutHead />
</head>
<body class="${pageProperty(name:'body.class')?:'nav-collections'}" id="${pageProperty(name:'body.id')}" onload="${pageProperty(name:'body.onload')}">

<div class="navbar navbar-inverse navbar-static-top">
    <div class="navbar-inner ">
        <div class="container">
            <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
            </button>
            <a class="brand" href="#">${raw(orgNameLong)}</a>
            <div class="nav-collapse collapse">
                <p class="navbar-text pull-right">
                    <g:message code="generic.navbar01.label" default="Logged in as"/> <a href="#" class="navbar-link">${username}</a>
                </p>
                <ul class="nav">
                    <li class="active"><a href="#"><g:message code="generic.navbar02.li01" default="Home"/></a></li>
                    <li><a href="#about"><g:message code="generic.navbar02.li02" default="About"/></a></li>
                    <li><a href="#contact"><g:message code="generic.navbar02.li03" default="Contact"/></a></li>
                </ul>
            </div><!--/.nav-collapse -->
        </div><!--/.container-fluid -->
    </div><!--/.navbar-inner -->
</div><!--/.navbar -->

<div class="container" id="main-content">
    <plugin:isAvailable name="alaAdminPlugin">
        <ala:systemMessage/>
    </plugin:isAvailable>
    <g:layoutBody />
</div><!--/.container-->

<div id="footer">
    <div class="container-fluid">
        <div class="row-fluid">
            <a href="https://creativecommons.org/licenses/by/3.0/au/" title="External link to Creative Commons"><img src="https://i.creativecommons.org/l/by/3.0/88x31.png" width="88" height="31" alt=""></a>
            <g:message code="generic.footer.link01" default="This site is licensed under a"/> <a href="https://creativecommons.org/licenses/by/3.0/au/" title="External link to Creative Commons" class="external"><g:message code="generic.footer.link02" default="Creative Commons Attribution 3.0 Australia License"/></a>.
            <g:message code="generic.footer.link03" default="Provider content may be covered by other"/> <a href="#terms-of-use" title="Terms of Use"><g:message code="generic.footer.link04" default="Terms of Use"/></a>.
        </div>
    </div>
</div><!--/#footer -->
<br/>

<!-- JS resources-->
<asset:deferredScripts/>
</body>
</html>
