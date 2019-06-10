package com.github.ened.login_with_amazon;

import android.content.Context;
import android.os.Handler;
import android.util.Log;
import com.amazon.identity.auth.device.AuthError;
import com.amazon.identity.auth.device.api.Listener;
import com.amazon.identity.auth.device.api.authorization.AuthCancellation;
import com.amazon.identity.auth.device.api.authorization.AuthorizationManager;
import com.amazon.identity.auth.device.api.authorization.AuthorizeListener;
import com.amazon.identity.auth.device.api.authorization.AuthorizeRequest;
import com.amazon.identity.auth.device.api.authorization.AuthorizeResult;
import com.amazon.identity.auth.device.api.authorization.ProfileScope;
import com.amazon.identity.auth.device.api.workflow.RequestContext;
import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.PluginRegistry.ViewDestroyListener;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterView;

/**
 * LoginWithAmazonPlugin
 */
public class LoginWithAmazonPlugin implements ActivityLifecycleListener, MethodCallHandler,
    ViewDestroyListener {

  private static final String TAG = "LoginWithAmazon";

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "login_with_amazon");
    LoginWithAmazonPlugin plugin = new LoginWithAmazonPlugin(registrar.context());
    channel.setMethodCallHandler(plugin);
    registrar.addViewDestroyListener(plugin);

    FlutterView flutterView = registrar.view();
    if (flutterView != null) {
      flutterView.addActivityLifecycleListener(plugin);
    }
  }

  private final RequestContext requestContext;
  private Result authResult;

  private Handler mainThreadHandler = new Handler();

  private LoginWithAmazonPlugin(Context context) {
    requestContext = RequestContext.create(context);
    requestContext.registerListener(new AuthorizeListener() {
      @Override
      public void onSuccess(final AuthorizeResult authorizeResult) {
        Log.d(TAG, "onSuccess: " + authorizeResult);
        mainThreadHandler.post(() -> {
          if (authResult != null) {
            authResult.success(authorizeResult.getUser().getUserEmail());
            authResult = null;
          }
        });
      }

      @Override
      public void onError(AuthError authError) {
        Log.d(TAG, "onError: " + authError);
        mainThreadHandler.post(() -> {
          if (authResult != null) {
            authResult.error("error", authError.toString(), authError.getType().value());
            authResult = null;
          }
        });
      }

      @Override
      public void onCancel(AuthCancellation authCancellation) {
        Log.d(TAG, "onCancel: " + authCancellation);
        mainThreadHandler.post(() -> {
          if (authResult != null) {
            authResult.success(null);
            authResult = null;
          }
        });
      }
    });
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("login")) {
      authResult = result;
      AuthorizationManager.authorize(new AuthorizeRequest
          .Builder(requestContext)
          .addScopes(ProfileScope.profile(), ProfileScope.userId())
          .build());
    } else if (call.method.equals("signOut")) {
      AuthorizationManager.signOut(requestContext.getContext(), new Listener<Void, AuthError>() {
        @Override
        public void onSuccess(Void aVoid) {
          mainThreadHandler.post(() -> result.success(null));
        }

        @Override
        public void onError(AuthError authError) {
          mainThreadHandler.post(() -> result.error("signOut", "error", null));
        }
      });
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onPostResume() {
    requestContext.onResume();
  }

  @Override
  public boolean onViewDestroy(FlutterNativeView flutterNativeView) {
    authResult = null;

    return false;
  }
}
