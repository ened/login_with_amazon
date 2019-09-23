package com.github.ened.login_with_amazon;

import androidx.test.rule.ActivityTestRule;

import com.github.ened.login_with_amazon_example.MainActivity;

import dev.flutter.plugins.instrumentationadapter.FlutterRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;

@RunWith(FlutterRunner.class)
public class MainActivityTest {
    @Rule
    public ActivityTestRule<MainActivity> rule = new ActivityTestRule<>(MainActivity.class);
}
