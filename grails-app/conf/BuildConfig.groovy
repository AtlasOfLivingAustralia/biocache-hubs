grails.servlet.version = "2.5" // Change depending on target container compliance (2.5 or 3.0)
grails.project.class.dir = "target/classes"
grails.project.test.class.dir = "target/test-classes"
grails.project.test.reports.dir = "target/test-reports"
grails.project.work.dir = "target/work"
grails.project.target.level = 1.6
grails.project.source.level = 1.6
//grails.project.war.file = "target/${appName}-${appVersion}.war"

grails.project.fork = [
    // configure settings for compilation JVM, note that if you alter the Groovy version forked compilation is required
    //  compile: [maxMemory: 256, minMemory: 64, debug: false, maxPerm: 256, daemon:true],

    // configure settings for the test-app JVM, uses the daemon by default
    test: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256, daemon:true],
    // configure settings for the run-app JVM
    run: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256, forkReserve:false],
    // configure settings for the run-war JVM
    war: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256, forkReserve:false],
    // configure settings for the Console UI JVM
    console: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256]
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
        inherits true // Whether to inherit repository definitions from plugins

        grailsPlugins()
        grailsHome()
        mavenLocal()
        grailsCentral()
        mavenCentral()
        // uncomment these (or add new ones) to enable remote dependency resolution from public Maven repositories
        //mavenRepo "http://repository.codehaus.org"
        //mavenRepo "http://download.java.net/maven/2/"
        //mavenRepo "http://repository.jboss.com/maven2/"
        mavenRepo "http://maven.ala.org.au/repository/"
    }

    dependencies {
        // specify dependencies here under either 'build', 'compile', 'runtime', 'test' or 'provided' scopes e.g.
        // runtime 'mysql:mysql-connector-java:5.1.27'
        // runtime 'org.postgresql:postgresql:9.3-1100-jdbc41'
        //runtime("au.org.ala:biocache-service:1.0-SNAPSHOT") {
        //    excludes "icu4j","servlet-api","spring-core","spring-context","spring-context-support","spring-beans","spring-web","spring-mvc"
        //}
        runtime "commons-httpclient:commons-httpclient:3.1"
        runtime "commons-lang:commons-lang:2.6"
        runtime "net.sf.supercsv:super-csv:2.1.0"
    }

    plugins {
        // plugins for the build system only
        build(  ":tomcat:7.0.50",
                ":release:3.0.1",
                ":rest-client-builder:1.0.3") {
            export = false
        }

        // plugins for the compile step
        //compile ":scaffolding:2.0.1"
        compile ':cache:1.1.1'
        compile ":cache-ehcache:1.0.0"

        // plugins needed at runtime but not for compilation
        //runtime ":hibernate:3.6.10.7" // or ":hibernate4:4.1.11.6"
        //runtime ":database-migration:1.3.8"
        //runtime ":jquery:1.10.2.2"
        runtime ":jquery:1.8.3"
        runtime ":resources:1.2.1"
        // Uncomment these (or add new ones) to enable additional resources capabilities
        //runtime ":zipped-resources:1.0.1"
        //runtime ":cached-resources:1.1"
        //runtime ":yui-minify-resources:0.1.5"

        runtime ":ala-web-theme:0.2-SNAPSHOT"
    }
}
