package au.org.ala.biocache.hubs

import grails.web.servlet.mvc.GrailsParameterMap

class MoreWebUtils {

    /**
     * Converts the given params into a query string started with ?
     *
     * Bug fix of Grails WebUtils.toQueryString that handles Collection type values as well
     *
     * @param params The params
     * @param encoding The encoding to use
     * @return The query string
     * @throws UnsupportedEncodingException If the given encoding is not supported
     */
    @SuppressWarnings("rawtypes")
    static String toQueryString(Map params, String encoding) throws UnsupportedEncodingException {
        if (encoding == null) encoding = "UTF-8"
        StringBuilder queryString = new StringBuilder("?")

        for (Iterator i = params.entrySet().iterator(); i.hasNext();) {
            Map.Entry entry = (Map.Entry) i.next()
            boolean hasMore = i.hasNext()
            boolean wasAppended = appendEntry(entry, queryString, encoding, "")
            if (hasMore && wasAppended) queryString.append('&')
        }
        return queryString.toString()
    }

    /**
     * Converts the given parameters to a query string using the default  UTF-8 encoding
     *
     * Bug fix of Grails WebUtils.toQueryString that handles Collection type values as well
     *
     * @param parameters The parameters
     * @return The query string
     * @throws UnsupportedEncodingException If UTF-8 encoding is not supported
     */
    @SuppressWarnings("rawtypes")
    static String toQueryString(Map parameters) throws UnsupportedEncodingException {
        return toQueryString(parameters, "UTF-8")
    }

    @SuppressWarnings("rawtypes")
    private static boolean appendEntry(Map.Entry entry, StringBuilder queryString, String encoding, String path) throws UnsupportedEncodingException {
        String name = entry.getKey().toString()
        Object value = entry.getValue()

        if (name.indexOf(".") > -1 && (value instanceof Map)) return false // multi-d params handled by recursion
        else if (value == null) value = ""
        else if (value instanceof Map) {
            Map child = (Map)value
            Set nestedEntrySet = child.entrySet()
            for (Iterator i = nestedEntrySet.iterator(); i.hasNext();) {
                Map.Entry childEntry = (Map.Entry) i.next()
                appendEntry(childEntry, queryString, encoding, entry.getKey().toString() + '.')
                boolean hasMore = i.hasNext()
                if (hasMore) queryString.append('&')
            }
        }
        else if (value instanceof Collection) {
            boolean start = true
            value.each {
                if (start) { start = false }
                else { queryString.append('&') }
                queryString.append(URLEncoder.encode(path + name, encoding))
                        .append('=')
                        .append(URLEncoder.encode(it.toString(), encoding))
            }
        }
        else {
            queryString.append(URLEncoder.encode(path + name, encoding))
                    .append('=')
                    .append(URLEncoder.encode(value.toString(), encoding))
        }
        return true
    }

}