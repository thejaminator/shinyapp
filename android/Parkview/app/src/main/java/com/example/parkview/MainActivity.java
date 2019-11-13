package com.example.parkview;

import androidx.appcompat.app.AppCompatActivity;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import android.webkit.GeolocationPermissions;
import android.webkit.WebChromeClient;
//import android.Manifest;
//import android.os.Build;
//import android.app.Dialog;
//import android.app.ProgressDialog;
//import android.os.Bundle;
//import android.webkit.GeolocationPermissions;
//import android.webkit.WebChromeClient;
//import android.webkit.WebView;
//import android.webkit.WebViewClient;
//
//Source:
//https://gist.github.com/soulduse/e5db22a33bd23ef4b816f06039f6e696

public class MainActivity extends Activity {
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        webView = findViewById(R.id.webview);
        webView.getSettings().setJavaScriptEnabled(true); // 자바스크립트 사용을 허용한다.
        webView.getSettings().setAppCacheEnabled(true);
        webView.getSettings().setDatabaseEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.setWebViewClient(new WebViewClient());  // 새로운 창을 띄우지 않고 내부에서 웹뷰를 실행시킨다.
        webView.setWebChromeClient(new WebChromeClient(){
            @Override
            public void onGeolocationPermissionsShowPrompt(String origin, GeolocationPermissions.Callback callback) {
                super.onGeolocationPermissionsShowPrompt(origin, callback);
                callback.invoke(origin, true, false);
            }
        });
        webView.loadUrl("https://jameschua.shinyapps.io/shinyapp/");
    }
}

//public class MainActivity extends Activity {
//
//    private WebView myWebView;
//
//    @Override
//    protected void onCreate(Bundle savedInstanceState) {
//        super.onCreate(savedInstanceState);
//        setContentView(R.layout.activity_main);
//
//        WebView myWebView = (WebView) findViewById(R.id.webView);
//        myWebView.loadUrl("https://jameschua.shinyapps.io/shinyapp/");
//        WebSettings webSettings = myWebView.getSettings();
//        webSettings.setJavaScriptEnabled(true);
//        myWebView.getSettings().setAppCacheEnabled(true);
//        myWebView.getSettings().setDatabaseEnabled(true);
//        myWebView.getSettings().setDomStorageEnabled(true);
//
//    }
//}
