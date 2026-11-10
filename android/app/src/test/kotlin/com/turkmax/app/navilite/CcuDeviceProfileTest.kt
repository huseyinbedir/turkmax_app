package com.turkmax.app.navilite

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CcuDeviceProfileTest {
    @Test
    fun `xmax part number selects 480x234`() {
        val profile = CcuDeviceProfile.fromPartNumber("006-B3952-03")
        assertEquals(480, profile.width)
        assertEquals(234, profile.height)
    }

    @Test
    fun `other or missing part numbers fall back to default`() {
        assertEquals(CcuDeviceProfile.DEFAULT, CcuDeviceProfile.fromPartNumber("006-B4160-00"))
        assertEquals(CcuDeviceProfile.DEFAULT, CcuDeviceProfile.fromPartNumber(null))
    }

    @Test
    fun `ccu name heuristic`() {
        assertTrue(CcuDeviceProfile.looksLikeCcu("YCCU_12345"))
        assertFalse(CcuDeviceProfile.looksLikeCcu("JBL Flip 6"))
        assertFalse(CcuDeviceProfile.looksLikeCcu(null))
    }
}
