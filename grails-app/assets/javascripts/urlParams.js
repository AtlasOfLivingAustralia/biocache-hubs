/*
 * urlParams.js — replaces purl.js
 */
(function (global) {
    'use strict';

    /**
     * Get a single query-string parameter from the current page URL.
     * Returns undefined if the param is absent.
     */
    function getUrlParam(name) {
        try {
            var sp = new global.URLSearchParams(global.location.search);
            return sp.has(name) ? sp.get(name) : undefined;
        } catch (e) {
            return undefined;
        }
    }

    /**
     * Get all values for a repeated query-string parameter (e.g. ?fq=a&fq=b).
     * Returns an array; empty if the param is absent.
     */
    function getUrlParamAll(name) {
        try {
            return new global.URLSearchParams(global.location.search).getAll(name);
        } catch (e) {
            return [];
        }
    }

    global.getUrlParam = getUrlParam;
    global.getUrlParamAll = getUrlParamAll;
})(typeof window !== 'undefined' ? window : this);

