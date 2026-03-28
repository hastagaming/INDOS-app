package com.indos.terminal

import android.app.Activity
import android.os.Bundle
import android.widget.EditText
import android.widget.TextView
import android.view.KeyEvent
import java.io.*

class MainActivity : Activity() {
    private lateinit var outputView: TextView
    private lateinit var inputField: EditText
    private var process: Process? = null
    private var out: OutputStream? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Setup UI sederhana (Output di atas, Input di bawah)
        // Kita bisa buat UI ini via XML nanti
        setupTerminalUI()

        // Mulai Shell INDOS
        startShell()
    }

    private fun startShell() {
        try {
            process = ProcessBuilder("/system/bin/sh").redirectErrorStream(true).start()
            out = process?.outputStream
            
            // Thread untuk membaca output shell secara real-time
            Thread {
                val reader = BufferedReader(InputStreamReader(process?.inputStream))
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    runOnUiThread { outputView.append(line + "\n") }
                }
            }.start()
        } catch (e: Exception) {
            outputView.text = "Error: ${e.message}"
        }
    }

    private fun setupTerminalUI() {
        // Logika untuk inisialisasi view
    }
}
