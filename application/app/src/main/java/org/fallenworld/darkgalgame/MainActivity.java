package org.fallenworld.darkgalgame;

import android.app.Dialog;
import android.provider.Settings;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {

    private static MainActivity instance;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        instance = this;

        // Example of a call to a native method
        TextView tv = (TextView) findViewById(R.id.sample_text);
        tv.setText(entry());
    }

    public static void alert(String message) {
        AlertDialog.Builder dialog = new AlertDialog.Builder(instance);
        dialog.setMessage(message).create().show();
    }

    /**
     * C/C++ JNI代码的入口点
     */
    public native String entry();

    //加载JNI库
    static {
        String PACKAGE_NAME = "org.fallenworld.darkgalgame";
        String APP_PATH = "/data/data/" + PACKAGE_NAME;
        System.load(APP_PATH + "/libwine.so");
        System.load(APP_PATH + "/wine");
    }
}
