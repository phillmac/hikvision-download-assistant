// Copyright (c) 2020 Ryan Richard

package rr.hikvisiondownloadassistant;

import java.io.IOException;
import java.util.Date;
import java.util.LinkedList;
import java.util.List;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.dataformat.xml.XmlMapper;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.StatusLine;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpRequestBase;
import org.apache.http.config.SocketConfig;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.util.EntityUtils;
import rr.hikvisiondownloadassistant.Model.CMSearchDescription;
import rr.hikvisiondownloadassistant.Model.CMSearchResult;
import rr.hikvisiondownloadassistant.Model.SearchMatchItem;
import rr.hikvisiondownloadassistant.Model.TimeSpan;

import static rr.hikvisiondownloadassistant.DateConverter.dateToApiString;
import static rr.hikvisiondownloadassistant.Model.PHOTOS_TRACK_ID;
import static rr.hikvisiondownloadassistant.Model.VIDEOS_TRACK_ID;

@Getter
@RequiredArgsConstructor
public class IsapiRestClient {

    private static final String POST = "POST";
    private static final XmlMapper xmlMapper = new XmlMapper();

    private final String host;
    private final String username;
    private final String password;

    public List<SearchMatchItem> searchVideos(Date fromDate, Date toDate) throws IOException, InterruptedException {
        return searchMedia(fromDate, toDate, VIDEOS_TRACK_ID);
    }

    public List<SearchMatchItem> searchPhotos(Date fromDate, Date toDate) throws IOException, InterruptedException {
        return searchMedia(fromDate, toDate, PHOTOS_TRACK_ID);
    }

    private List<SearchMatchItem> searchMedia(Date fromDate, Date toDate, int trackId) throws IOException, InterruptedException {
        List<SearchMatchItem> allResults = new LinkedList<>();
        CMSearchResult searchResult;
        final int maxResults = 50;
        int searchResultPosition = 0;

        do {
            searchResult = doHttpRequest(
                    POST,
                    "/ISAPI/ContentMgmt/search",
                    getSearchRequestBodyXml(fromDate, toDate, trackId, searchResultPosition, maxResults),
                    CMSearchResult.class
            );

            List<SearchMatchItem> matches = searchResult.getMatchList();
            if (matches != null) {
                allResults.addAll(matches);
            }
            searchResultPosition += maxResults;

        } while (searchResult.isResponseStatus() && searchResult.getResponseStatusStrg().equalsIgnoreCase("more"));

        return allResults;
    }

    private String getSearchRequestBodyXml(Date fromDate, Date toDate, int trackId, int searchResultPosition, int maxResults) throws JsonProcessingException {
        return xmlMapper.writerWithDefaultPrettyPrinter().writeValueAsString(
                CMSearchDescription.builder()
                        .maxResults(maxResults)
                        .searchResultPosition(searchResultPosition)
                        .timeSpan(List.of(TimeSpan.builder()
                                .startTime(dateToApiString(fromDate))
                                .endTime(dateToApiString(toDate))
                                .build()))
                        .trackID(List.of(trackId))
                        .build()
        );
    }

    private <T> T doHttpRequest(String requestMethod, String requestPath, String body, Class<T> resultClass) throws IOException, InterruptedException {
        // Make the first request without an authorization header so we can get the digest challenge response.
        // See https://tools.ietf.org/html/rfc2617
        HttpResponse unauthorizedResponse = doHttpRequestWithAuthHeader(requestMethod, requestPath, body, null);
        StatusLine unauthorizedStatusLine = unauthorizedResponse.getStatusLine();

        if (unauthorizedStatusLine.getStatusCode() != 401) {
            throw new RuntimeException("Expected to get a 401 digest auth challenge response but got response code " + unauthorizedStatusLine.getStatusCode());
        }

        // Calculate the authorization digest value
        String authorizationHeaderValue = new DigestAuth(unauthorizedResponse, requestMethod, requestPath, username, password)
                .getAuthorizationHeaderValue();

        // Resend the request
        HttpResponse response = doHttpRequestWithAuthHeader(requestMethod, requestPath, body, authorizationHeaderValue);
        StatusLine statusLine = response.getStatusLine();

        if (statusLine.getStatusCode() == 401) {
            throw new RuntimeException("Could not authenticate. Wrong username or password?");
        }
        if (statusLine.getStatusCode() != 200) {
            throw new RuntimeException("Expected to get successful response but got response code " + statusLine.getStatusCode());
        }

        HttpEntity entity = response.getEntity();
        String responseBody = entity != null ? EntityUtils.toString(entity) : null;

        EntityUtils.consume(entity);

        // Avoid a jackson parsing error where it doesn't like empty lists
        String workaroundForEmptyResult = responseBody.replaceAll("<matchList>\\s+</matchList>", "<matchList/>");

        // Return the parsed response
        return xmlMapper.readValue(workaroundForEmptyResult, resultClass);
    }

    private HttpResponse doHttpRequestWithAuthHeader(String requestMethod, String path, String body, String authHeaderValue) throws IOException {
        SocketConfig socketConfig = SocketConfig.custom().setSoKeepAlive(true).setSoTimeout(1800000).build();
        RequestConfig requestConfig = RequestConfig.custom().setConnectTimeout(1800000).build();
        CloseableHttpClient httpClient = HttpClientBuilder.create().setDefaultRequestConfig(requestConfig).
            setDefaultSocketConfig(socketConfig).build();

        HttpRequestBase request;
        if (requestMethod.equals("POST")) {
            HttpPost postRequest = new HttpPost("http://" + host + path);
            if (body != null) {
                postRequest.setEntity(new StringEntity(body));
            }
            request = postRequest;
        } else if (requestMethod.equals("GET")) {
            request = new HttpGet("http://" + host + path);
        } else {
            throw new IllegalArgumentException("Unsupported request method: " + requestMethod);
        }

        request.setHeader("Accept", "application/xml");
        if (authHeaderValue != null) {
            request.setHeader("Authorization", authHeaderValue);
        }

        HttpResponse response = httpClient.execute(request);
        return response;
    }

}
