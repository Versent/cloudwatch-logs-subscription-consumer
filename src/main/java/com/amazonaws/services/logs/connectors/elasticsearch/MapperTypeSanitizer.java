package com.amazonaws.services.logs.connectors.elasticsearch;

import java.util.regex.Pattern;

/**
 * Removes invalid characters from a mapper type.
 */
public class MapperTypeSanitizer {

    private static final String INVALID_CHARS = "^[_]|[#,]";
    private static final Pattern PATTERN = Pattern.compile(INVALID_CHARS);
    private static final String REPLACEMENT_STRING = "";

    public static String sanitizeMapperType(String logGroupName) {
        return PATTERN.matcher(logGroupName).replaceAll(REPLACEMENT_STRING);
    }
}
