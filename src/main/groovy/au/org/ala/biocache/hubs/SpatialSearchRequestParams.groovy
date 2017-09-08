package au.org.ala.biocache.hubs

import grails.validation.Validateable

/**
 * Created with IntelliJ IDEA.
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
class SpatialSearchRequestParams extends SearchRequestParams implements Validateable {
    protected Float radius = null;
    protected Float lat = null;
    protected Float lon = null;
    protected String wkt ="";
    protected Boolean gk = false; //include only the geospatially kosher records
    private String[] gkFq = ["geospatial_kosher:true"] // groovy syntax

    /**
     * Custom toString method to produce a String to be used as the request parameters
     * for the Biocache Service webservices
     *
     * @return request parameters string
     */
    @Override
    public String toString() {
        return addSpatialParams(super.toString(), false);
    }

    /**
     * Produce a URI encoded query string for use in java.util.URI, etc
     *
     * @return
     */
    public String getEncodedParams() {
        return addSpatialParams(super.getEncodedParams(), true);
    }

    /**
     * Add the spatial params to the param string
     *
     * @param paramString
     * @return
     */
    protected String addSpatialParams(String paramString, Boolean encodeParams) {
        StringBuilder req = new StringBuilder(paramString);
        if (lat != null && lon != null && radius != null) {
            req.append("&lat=").append(lat);
            req.append("&lon=").append(lon);
            req.append("&radius=").append(radius);
        }
        if(wkt != null && wkt.length() >0)
            req.append("&wkt=").append(conditionalEncode(wkt, encodeParams));
        if(gk)
            req.append("&gk=true");
        return req.toString();
    }

    @Override
    public String getUrlParams(){
        StringBuilder req = new StringBuilder(super.getUrlParams());
        if (lat != null && lon != null && radius != null) {
            req.append("&lat=").append(lat);
            req.append("&lon=").append(lon);
            req.append("&radius=").append(radius);
        }
        if(wkt != null && wkt.length() >0)
            req.append("&wkt=").append(wkt);
        return req.toString();
    }
}
