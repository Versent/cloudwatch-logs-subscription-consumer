package com.amazonaws.services.logs.connectors.elasticsearch;

import java.util.regex.Pattern;

/**
 * Removes invalid characters from the log group name which gets used at the type name in elastic search.
 */
public class MapperLogGroupSanitizer {

    private static final String INVALID_CHARS = "^[_]|[#,\\.]";
    private static final Pattern PATTERN = Pattern.compile(INVALID_CHARS);
    private static final String REPLACEMENT_STRING = "";

    public static String sanitizeMapperLogGroupName(String logGroupName) {
        return PATTERN.matcher(logGroupName).replaceAll(REPLACEMENT_STRING);
    }
}
