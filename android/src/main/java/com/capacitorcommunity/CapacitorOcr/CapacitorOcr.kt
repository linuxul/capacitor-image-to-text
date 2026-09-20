// The package keeps the name the Java sources used.
@file:Suppress("ktlint:standard:package-name")

package com.capacitorcommunity.CapacitorOcr

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import android.provider.MediaStore
import android.util.Base64
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import java.io.IOException

@CapacitorPlugin(name = "CapacitorOcr")
public class CapacitorOcr : Plugin() {
    @PluginMethod
    @Throws(IOException::class)
    public fun detectText(call: PluginCall) {
        val rotation = orientationToRotation(call.getString("orientation") ?: "UP")

        val filename = call.getString("filename")
        val base64 = call.getString("base64")
        val bitmap: Bitmap

        if (filename != null) {
            @Suppress("DEPRECATION")
            val loaded: Bitmap? = MediaStore.Images.Media.getBitmap(context.contentResolver, Uri.parse(filename))
            if (loaded == null) {
                call.reject("Could not load image from path")
                return
            }
            bitmap = loaded
        } else if (base64 != null) {
            val imageData = Base64.decode(base64.substring(base64.indexOf(",") + 1), Base64.DEFAULT)

            val decoded: Bitmap? = BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
            if (decoded == null) {
                call.reject("Could not load image from base64")
                return
            }
            bitmap = decoded
        } else {
            call.reject("Invalid image input")
            return
        }

        val matrix = Matrix()
        matrix.setRotate(rotation.toFloat())
        val rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)

        TextDetector().detectText(call, rotatedBitmap)
    }

    private fun orientationToRotation(orientation: String): Int = when (orientation) {
        "UP" -> 0
        "RIGHT" -> 90
        "DOWN" -> 180
        "LEFT" -> 270
        else -> 0
    }
}
