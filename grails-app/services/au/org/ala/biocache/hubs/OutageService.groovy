package au.org.ala.biocache.hubs

import grails.converters.JSON
import grails.plugin.cache.CacheEvict
import grails.plugin.cache.Cacheable
import groovy.json.JsonBuilder
import groovy.json.JsonSlurper

/**
 * Get/Set the outage message for the outage banner (admin)
 */
class OutageService {

    private final static String FILE_NAME = "biocacheHubsOutage.json"
    private final static String TMP_PATH = System.getProperty("java.io.tmpdir")
    private final static String FILE_PATH = TMP_PATH + File.separator + FILE_NAME

    @Cacheable("outageCache")
    public OutageBanner getOutageBanner() {
        OutageBanner outageBanner = new OutageBanner();
        //ObjectMapper mapper = new ObjectMapper();
        log.debug("get FILE_PATH = " + FILE_PATH);

        try {
            //outageBanner = mapper.readValue(new File(FILE_PATH), OutageBanner.class);
            def jsonText = new File(FILE_PATH).text
            if (jsonText) {
                outageBanner = new JsonSlurper().parseText(jsonText)
            }

        } catch (IOException e) {
            log.warn("Outage message JSON not found: " + e.getMessage());
        }

        //log.debug "outageBanner = " + outageBanner?.toJson() as JSON
        return outageBanner;
    }

    public void setOutageBanner(OutageBanner outageBanner) {
        //ObjectMapper mapper = new ObjectMapper();
        log.debug("set FILE_PATH = " + FILE_PATH);

        try {
            def outputFile = new File(FILE_PATH)
            def jb = new JsonBuilder( outageBanner.toMap() ) // map avoids errors field injected by @Validateable
            outputFile.write(jb.toString())
        } catch (IOException e) {
            log.error("Failed to write outage JSON: " + e.getMessage(), e);
        }
    }

    @CacheEvict(value='outageCache', allEntries=true)
    public void clearOutageCache() {
        log.info("Clearing outage banner cache");
    }
}
