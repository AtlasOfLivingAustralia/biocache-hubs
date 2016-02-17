package au.org.ala.biocache.hubs

import grails.util.Holders
import grails.validation.Validateable
import groovy.util.logging.Log4j
import org.apache.commons.httpclient.URIException
import org.apache.commons.httpclient.util.URIUtil

/**
 * Data Transfer Object to represent the request parameters required to search
 * for occurrence records against biocache-service.
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
@Validateable
@Log4j
public class SearchRequestParams {
    Long qId // "qid:12312321"
    String formattedQuery
    String q = ""
    String[] fq = []; // must not be null
    String fl = ""
    /** The facets to be included by the search Initialised with the default facets to use */
    String[] facets = [] // get from http://biocache.ala.org.au/ws/search/facets (and cache) // FacetThemes.allFacets;
    /** The limit for the number of facets to return */
    Integer flimit = 10
    /** The sort order in which to return the facets.  Either count or index.  When empty string the default values are used as defined in the Theme based facets */
    String fsort = ""
    /** The offset of facets to return.  Used in conjunction to flimit */
    Integer foffset = 0
    /** The prefix to limit facet values*/
    String fprefix = ""
    /**  pagination params */
    Integer start = 0
    Integer offset // grails version of start
    Integer pageSize = 10
    Integer max // grails version of pageSize
    String sort = "score"
    String dir = "asc"
    String displayString
    /**  The query context to be used for the search.  This will be used to generate extra query filters based on the search technology */
    String qc = Holders.config.biocache.queryContext?:""
    /** To disable facets */
    Boolean facet = true

    /**
     * Custom toString method to produce a String to be used as the request parameters
     * for the Biocache Service webservices
     *
     * @return request parameters string
     */
    @Override
    public String toString() {
        return toString(false);
    }

    /**
     * Produce a URI encoded query string for use in java.util.URI, etc
     *
     * @return encoded query string
     */
    public String getEncodedParams() {
        return toString(true);
    }

    /**
     * Common code to output a param string with conditional encoding of values
     *
     * @param encodeParams
     * @return query string
     */
    public String toString(Boolean encodeParams) {
        StringBuilder req = new StringBuilder();
        req.append("q=").append(conditionalEncode(q, encodeParams));
        fq.each { filter ->
            req.append("&fq=").append(conditionalEncode(filter, encodeParams))
        }
        req.append("&start=").append(offset?:start);
        req.append("&pageSize=").append(max?:pageSize);
        req.append("&sort=").append(sort);
        req.append("&dir=").append(dir);
        req.append("&qc=").append(conditionalEncode(qc, encodeParams));
        if (facet && facets?.length > 0) {
            for (String f : facets) {
                req.append("&facets=").append(conditionalEncode(f, encodeParams));
            }
        }
        if (flimit != 30)
            req.append("&flimit=").append(flimit);
        if (fl.length() > 0)
            req.append("&fl=").append(conditionalEncode(fl, encodeParams));
        if(formattedQuery)
            req.append("&formattedQuery=").append(conditionalEncode(formattedQuery, encodeParams));
        if(!facet)
            req.append("&facet=false");
        if(!"".equals(fsort))
            req.append("&fsort=").append(fsort);
        if(foffset > 0)
            req.append("&foffset=").append(foffset);
        if(!"".equals(fprefix))
            req.append("&fprefix=").append(fprefix);

        return req.toString();
    }

    /**
     * URI encode the param value if isEncoded is true
     *
     * @param input
     * @param isEncoded
     * @return query string
     */
    public String conditionalEncode(String input, Boolean isEncoded) {
        String output;
        
        if (input == null) {
            output = "";
        } else if (isEncoded) {
            try {
                output = URIUtil.encodeWithinQuery(input);
            } catch (URIException e) {
                logger.warn("URIUtil encoding error: " + e.getMessage(), e);
                output = input;
            }
        } else {
            output = input;
        }

        return output;
    }

    /**
     * Constructs the params to be returned in the result
     * @return req
     */
    public String getUrlParams(){
        StringBuilder req = new StringBuilder();
        if(qId != null){
            req.append("?q=qid:").append(qId);
        } else {
            try{
                req.append("?q=").append(URLEncoder.encode(q, "UTF-8"));
            } catch(UnsupportedEncodingException e){}
        }


        for(String f : fq){
            //only add the fq if it is not the query context
            if(f.length()>0 && !f.equals(qc))
                try{
                    req.append("&fq=").append(URLEncoder.encode(f, "UTF-8"));
                } catch(UnsupportedEncodingException e){}
        }

        if(qc != ""){
            req.append("&qc=").append(URLEncoder.encode(qc, "UTF-8"));
        }
        return req.toString();
    }
}
