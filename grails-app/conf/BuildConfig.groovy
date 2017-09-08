grails.servlet.version = "3.0" // Change depending on target container compliance (2.5 or 3.0)
grails.project.class.dir = "target/classes"
grails.project.test.class.dir = "target/test-classes"
grails.project.test.reports.dir = "target/test-reports"
grails.project.work.dir = "target/work"
grails.project.target.level = 1.8
grails.project.source.level = 1.8
//grails.project.war.file = "target/${appName}-${appVersion}.war"
//grails.plugin.location.'images-client-plugin' = "../images-client-plugin"
//grails.plugin.location.'ala-charts-plugin' = "../ala-charts-plugin"

grails.project.fork = [
        test: false,
        run: false
]

grails.project.dependency.resolver = "maven" // or ivy
grails.project.dependency.resolution = {
    // inherit Grails' default dependencies
    inherits("global") {
        // specify dependency exclusions here; for example, uncomment this to disable ehcache:
        // excludes 'ehcache'
    }
    log "error" // log level of Ivy resolver, either 'error', 'warn', 'info', 'debug' or 'verbose'
    checksums true // Whether to verify checksums on resolve
    legacyResolve false // whether to do a secondary resolve on plugin installation, not advised and here for backwards compatibility

    repositories {
        mavenLocal()
        mavenRepo ("http://nexus.ala.org.au/content/groups/public/")
    }

    dependencies {
        // specify dependencies here under either 'build', 'compile', 'runtime', 'test' or 'provided' scopes e.g.
        // runtime 'mysql:mysql-connector-java:5.1.27'
        // runtime 'org.postgresql:postgresql:9.3-1100-jdbc41'
        //runtime("au.org.ala:biocache-service:1.0-SNAPSHOT") {
        //    excludes "icu4j","servlet-api","spring-core","spring-context","spring-context-support","spring-beans","spring-web","spring-mvc"
        //}
        //compile "org.tmatesoft.svnkit:svnkit:1.8.5"
        compile "commons-httpclient:commons-httpclient:3.1"
        runtime "commons-lang:commons-lang:2.6"
        runtime "net.sf.supercsv:super-csv:2.1.0"
    }

    plugins {
        build(  ":tomcat:7.0.54",
                ":release:3.1.1",
                ":rest-client-builder:2.1.1") {
            export = false
        }
        compile ':cache:1.1.8'
        compile ":cache-ehcache:1.0.0"
        compile ":rest:0.8"
        compile ":build-info:1.2.6"
        runtime ":jquery:1.11.1"
        compile ":asset-pipeline:2.14.1"
        runtime ":release:3.1.1"
        runtime ":ala-admin-plugin:1.3"
        runtime ":ala-charts-plugin:1.3"
        compile ":images-client-plugin:0.8"
    }
}
