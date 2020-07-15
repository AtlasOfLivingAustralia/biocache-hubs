package au.org.ala.biocache.hubs;

import java.util.List;

public class OccurrenceNavigationDTO {
    private SpatialSearchRequestParams searchRequestParams;
    private List<String> currentPageUUIDs;
    private String currentUUID;

    public SpatialSearchRequestParams getSearchRequestParams() {
        return searchRequestParams;
    }

    public void setSearchRequestParams(SpatialSearchRequestParams searchRequestParams) {
        this.searchRequestParams = searchRequestParams;
    }

    public List<String> getCurrentPageUUIDs() {
        return currentPageUUIDs;
    }

    public void setCurrentPageUUIDs(List<String> currentPageUUIDs) {
        this.currentPageUUIDs = currentPageUUIDs;
    }

    public String getCurrentUUID() {
        return currentUUID;
    }

    public void setCurrentUUID(String currentUUID) {
        this.currentUUID = currentUUID;
    }
}
