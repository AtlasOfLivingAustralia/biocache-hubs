//grails.plugin.myplugin.name=appName

log4j = {
    // Example of changing the log pattern for the default console appender:
    //
    //appenders {
    //    console name:'stdout', layout:pattern(conversionPattern: '%c{2} %m%n')
    //}

//    appenders {
//        environments {
//            production {
//                rollingFile name: "tomcatLog", maxFileSize: 102400000, file: "/var/log/tomcat6/${appName}.log", threshold: org.apache.log4j.Level.ERROR, layout: pattern(conversionPattern: "%d %-5p [%c{1}] %m%n")
//                'null' name: "stacktrace"
//            }
//            development {
//                console name: "stdout", layout: pattern(conversionPattern: "%d %-5p [%c{1}]  %m%n"), threshold: org.apache.log4j.Level.INFO
//            }
//            test {
//                rollingFile name: "tomcatLog", maxFileSize: 102400000, file: "/tmp/${appName}-test.log", threshold: org.apache.log4j.Level.DEBUG, layout: pattern(conversionPattern: "%d %-5p [%c{1}]  %m%n")
//                'null' name: "stacktrace"
//            }
//        }
//    }
//
//    root {
//        // change the root logger to my tomcatLog file
//        error 'tomcatLog'
//        warn 'tomcatLog'
//        additivity = true
//    }
//
//    error  'org.codehaus.groovy.grails.web.servlet',        // controllers
//           'org.codehaus.groovy.grails.web.pages',          // GSP
//           'org.codehaus.groovy.grails.web.sitemesh',       // layouts
//           'org.codehaus.groovy.grails.web.mapping.filter', // URL mapping
//           'org.codehaus.groovy.grails.web.mapping',        // URL mapping
//           'org.codehaus.groovy.grails.commons',            // core / classloading
//           'org.codehaus.groovy.grails.plugins',            // plugins
//           'org.codehaus.groovy.grails.orm.hibernate',      // hibernate integration
//           'org.springframework',
//           'org.hibernate',
//           'net.sf.ehcache.hibernate'
//    debug  'grails.app.controllers',
//           'grails.app.services',
//           //'grails.app.taglib',
//           'au.org.ala.cas',
//           'au.org.ala.biocache.hubs'
}
