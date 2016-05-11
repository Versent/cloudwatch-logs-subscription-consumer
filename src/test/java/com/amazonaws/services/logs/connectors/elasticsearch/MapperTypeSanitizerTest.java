package com.amazonaws.services.logs.connectors.elasticsearch;

import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class MapperTypeSanitizerTest {


        @Test
        public void sanitizeMapperType(){

            assertEquals("Hello dude", MapperTypeSanitizer.sanitizeMapperType("Hello dude"));
            assertEquals("Hello_dude", MapperTypeSanitizer.sanitizeMapperType("_Hello_dude"));
            assertEquals("Hellodude", MapperTypeSanitizer.sanitizeMapperType(",Hello,dude,"));
            assertEquals("Hellodude", MapperTypeSanitizer.sanitizeMapperType("#Hello#dude#"));
            assertEquals("xxxxxxxx", MapperTypeSanitizer.sanitizeMapperType("_xxxx#xx##,xx"));
        }
}
