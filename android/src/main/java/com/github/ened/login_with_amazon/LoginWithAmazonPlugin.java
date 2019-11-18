package com.github.ened.login_with_amazon;

import android.content.Context;
import android.os.Handler;
import android.text.TextUtils;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.amazon.identity.auth.device.AuthError;
import com.amazon.identity.auth.device.api.Listener;
import com.amazon.identity.auth.device.api.SDKInfo;
import com.amazon.identity.auth.device.api.authorization.AuthCancellation;
import com.amazon.identity.auth.device.api.authorization.AuthorizationManager;
import com.amazon.identity.auth.device.api.authorization.AuthorizeListener;
import com.amazon.identity.auth.device.api.authorization.AuthorizeRequest;
import com.amazon.identity.auth.device.api.authorization.AuthorizeResult;
import com.amazon.identity.auth.device.api.authorization.Scope;
import com.amazon.identity.auth.device.api.authorization.ScopeFactory;
import com.amazon.identity.auth.device.api.authorization.User;
import com.amazon.identity.auth.device.api.workflow.RequestContext;
import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.PluginRegistry.ViewDestroyListener;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterView;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.json.JSONObject;

/** LoginWithAmazonPlugin */
public class LoginWithAmazonPlugin
    implements ActivityLifecycleListener, MethodCallHandler, ViewDestroyListener {

  private static final String TAG = "LoginWithAmazon";

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel =
        new MethodChannel(registrar.messenger(), "com.github.ened/login_with_amazon");
    LoginWithAmazonPlugin plugin = new LoginWithAmazonPlugin(registrar.context());
    channel.setMethodCallHandler(plugin);

    final EventChannel userChannel =
        new EventChannel(registrar.messenger(), "com.github.ened/login_with_amazon/user");
    userChannel.setStreamHandler(plugin.userStreamHandler);

    registrar.addViewDestroyListener(plugin);

    FlutterView flutterView = registrar.view();
    if (flutterView != null) {
      flutterView.addActivityLifecycleListener(plugin);
    }
  }

  private final Context context;

  @Nullable private RequestContext requestContext;

  @Nullable private Result authResult;

  private Handler mainThreadHandler = new Handler();

  @Nullable private EventSink userStreamEventSink;

  private LoginWithAmazonPlugin(Context context) {
    this.context = context;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "version":
        result.success(SDKInfo.VERSION);
        break;

      case "login":
        ensureRequestContext(context);

        authResult = result;

        assert requestContext != null;

        final Map<String, Object> scopeArguments = Objects.requireNonNull(call.argument("scopes"));

        final String grantType = call.argument("grantType");

        List<Scope> scopes = new ArrayList<>();

        for (String name : scopeArguments.keySet()) {
          Object tmp = scopeArguments.get(name);
          if (tmp instanceof Map) {
            Map scopeData = (Map) tmp;
            scopes.add(ScopeFactory.scopeNamed(name, new JSONObject(scopeData)));
          } else {
            scopes.add(ScopeFactory.scopeNamed(name));
          }
        }

        Log.d(TAG, "Logging in with scopes: " + TextUtils.join(", ", scopes));

        AuthorizeRequest.GrantType gt =
            "access_token".equals(grantType)
                ? AuthorizeRequest.GrantType.ACCESS_TOKEN
                : AuthorizeRequest.GrantType.AUTHORIZATION_CODE;

        Log.d(TAG, "grantType: " + grantType);

        AuthorizeRequest.Builder builder =
            new AuthorizeRequest.Builder(requestContext).forGrantType(gt);

        builder.addScopes(scopes.toArray(new Scope[] {}));

        if (gt == AuthorizeRequest.GrantType.AUTHORIZATION_CODE) {
          builder.withProofKeyParameters(
              call.argument("codeChallenge"), call.argument("codeChallengeMethod"));
        }

        AuthorizationManager.authorize(builder.build());

        break;

      case "signOut":
        AuthorizationManager.signOut(
            context,
            new Listener<Void, AuthError>() {
              @Override
              public void onSuccess(Void aVoid) {
                mainThreadHandler.post(
                    () -> {
                      if (userStreamEventSink != null) {
                        userStreamEventSink.success(null);
                      }
                      result.success(null);
                    });
              }

              @Override
              public void onError(AuthError authError) {
                mainThreadHandler.post(() -> result.error("signOut", "error", null));
              }
            });
        break;

      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onPostResume() {
    if (requestContext != null) {
      requestContext.onResume();
    }
  }

  @Override
  public boolean onViewDestroy(FlutterNativeView flutterNativeView) {
    authResult = null;

    if (userStreamEventSink != null) {
      userStreamEventSink.endOfStream();
    }
    userStreamEventSink = null;

    return false;
  }

  private void ensureRequestContext(Context context) {
    if (requestContext != null) {
      return;
    }

    requestContext = RequestContext.create(context);

    AuthorizeListener authorizeListener =
        new AuthorizeListener() {
          @Override
          public void onSuccess(final AuthorizeResult authorizeResult) {
            Log.d(TAG, "onSuccess: " + authorizeResult);

            final Map<String, Object> authMap = new HashMap<>();
            authMap.put("accessToken", authorizeResult.getAccessToken());
            authMap.put("authorizationCode", authorizeResult.getAuthorizationCode());
            authMap.put("clientId", authorizeResult.getClientId());
            authMap.put("redirectURI", authorizeResult.getRedirectURI());
            authMap.put("user", userToMap(authorizeResult.getUser()));

            mainThreadHandler.post(
                () -> {
                  if (userStreamEventSink != null) {
                    userStreamEventSink.success(authMap);
                  }
                });

            final User user = authorizeResult.getUser();
            final Map<String, Object> userMap = userToMap(user);

            mainThreadHandler.post(
                () -> {
                  if (userStreamEventSink != null) {
                    userStreamEventSink.success(userMap);
                  }
                });

            mainThreadHandler.post(
                () -> {
                  if (authResult != null) {
                    authResult.success(authMap);
                    authResult = null;
                  }
                });
          }

          @Override
          public void onError(AuthError authError) {
            Log.d(TAG, "onError: " + authError);
            mainThreadHandler.post(
                () -> {
                  if (authResult != null) {
                    authResult.error("error", authError.toString(), authError.getType().value());
                    authResult = null;
                  }
                });
          }

          @Override
          public void onCancel(AuthCancellation authCancellation) {
            Log.d(TAG, "onCancel: " + authCancellation);
            mainThreadHandler.post(
                () -> {
                  if (authResult != null) {
                    authResult.success(null);
                    authResult = null;
                  }
                });
          }
        };

    requestContext.registerListener(authorizeListener);
  }

  private Map<String, Object> userToMap(@Nullable User user) {
    final Map<String, Object> map = new HashMap<>();

    if (user != null) {
      map.put("email", user.getUserEmail());
      map.put("name", user.getUserName());
      map.put("postalCode", user.getUserPostalCode());
      map.put("userId", user.getUserId());
    }

    return map;
  }

  private void fetchCurrentUser() {
    User.fetch(
        context,
        new Listener<User, AuthError>() {
          @Override
          public void onSuccess(User user) {
            Log.d(TAG, "Current user: " + user.getUserEmail());
            final Map<String, Object> map = userToMap(user);

            mainThreadHandler.post(
                () -> {
                  if (userStreamEventSink != null) {
                    userStreamEventSink.success(map);
                  }
                });
          }

          @Override
          public void onError(AuthError authError) {
            Log.e(TAG, "authError: " + authError);
            mainThreadHandler.post(
                () -> {
                  if (userStreamEventSink != null) {
                    userStreamEventSink.success(null);
                  }
                });
          }
        });
  }

  private final StreamHandler userStreamHandler =
      new StreamHandler() {
        @Override
        public void onListen(Object o, EventSink eventSink) {
          userStreamEventSink = eventSink;

          fetchCurrentUser();
        }

        @Override
        public void onCancel(Object o) {
          userStreamEventSink = null;
        }
      };
}
