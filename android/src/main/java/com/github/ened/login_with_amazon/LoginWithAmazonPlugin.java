package com.github.ened.login_with_amazon;

import android.content.Context;
import android.os.Handler;
import android.text.TextUtils;
import android.util.Base64;
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
import com.amazon.identity.auth.device.api.authorization.ProfileScope;
import com.amazon.identity.auth.device.api.authorization.Scope;
import com.amazon.identity.auth.device.api.authorization.ScopeFactory;
import com.amazon.identity.auth.device.api.authorization.User;
import com.amazon.identity.auth.device.api.workflow.RequestContext;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

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

/** LoginWithAmazonPlugin */
public class LoginWithAmazonPlugin
    implements ActivityLifecycleListener, MethodCallHandler, ViewDestroyListener {

  private static final String TAG = "LoginWithAmazon";

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel =
        new MethodChannel(registrar.messenger(), "com.github.ened/login_with_amazon");
    LoginWithAmazonPlugin plugin = new LoginWithAmazonPlugin(registrar.activeContext());
    channel.setMethodCallHandler(plugin);

    final EventChannel userChannel =
        new EventChannel(registrar.messenger(), "com.github.ened/login_with_amazon/user");
    userChannel.setStreamHandler(plugin.userStreamHandler);

    final EventChannel authorizationChannel =
        new EventChannel(registrar.messenger(), "com.github.ened/login_with_amazon/authorization");
    authorizationChannel.setStreamHandler(plugin.authorizationStreamHandler);

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
  @Nullable private EventSink authorizationEventSink;

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

        final List<Scope> scopes = parseScopes(Objects.requireNonNull(call.argument("scopes")));

        List<String> scopeNames = new ArrayList<>();
        for (Scope scope : scopes) {
          scopeNames.add(scope.getName());
        }

        Log.d(TAG, "Logging in with scopes: " + TextUtils.join(", ", scopeNames));

        AuthorizationManager.authorize(
            new AuthorizeRequest.Builder(requestContext)
                .addScopes(scopes.toArray(new Scope[] {}))
                .build());

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

  private String generateCodeChallenge(String codeVerifier, String codeChallengeMethod)
      throws NoSuchAlgorithmException {
    String codeChallenge =
        Base64.encodeToString(
            MessageDigest.getInstance("SHA256").digest(codeVerifier.getBytes()),
            Base64.URL_SAFE | Base64.NO_PADDING | Base64.NO_WRAP);
    return codeChallenge;
  }

  private String generateCodeVerifier() {
    byte[] randomOctetSequence = generateRandomOctetSequence();
    String codeVerifier =
        Base64.encodeToString(
            randomOctetSequence, Base64.URL_SAFE | Base64.NO_PADDING | Base64.NO_WRAP);
    return codeVerifier;
  }

  /**
   * * As per Proof Key/SPOP protocol Version 10 * @return a random 32 sized octet sequence from
   * allowed range
   */
  private byte[] generateRandomOctetSequence() {
    SecureRandom random = new SecureRandom();
    byte[] octetSequence = new byte[32];
    random.nextBytes(octetSequence);

    return octetSequence;
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

    return false;
  }

  private void ensureRequestContext(Context context) {
    if (requestContext != null) {
      return;
    }

    requestContext = RequestContext.create(context);
    requestContext.registerListener(
        new AuthorizeListener() {
          @Override
          public void onSuccess(final AuthorizeResult authorizeResult) {
            Log.d(TAG, "onSuccess: " + authorizeResult);

            final Map<String, Object> authMap = new HashMap<>();
            authMap.put("accessToken", authorizeResult.getAccessToken());
            authMap.put("authorizationCode", authorizeResult.getAuthorizationCode());
            authMap.put("clientId", authorizeResult.getClientId());
            authMap.put("redirectURI", authorizeResult.getRedirectURI());

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
        });
  }

  private Map<String, Object> userToMap(User user) {
    final Map<String, Object> map = new HashMap<>();
    map.put("email", user.getUserEmail());
    map.put("name", user.getUserName());
    map.put("postalCode", user.getUserPostalCode());
    map.put("userId", user.getUserId());
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

  private List<Scope> parseScopes(List<String> list) {
    List<Scope> scopes = new ArrayList<>();

    for (String str : list) {
      if ("profile".equalsIgnoreCase(str)) {
        scopes.add(ProfileScope.profile());
      } else if ("userId".equalsIgnoreCase(str)) {
        scopes.add(ProfileScope.userId());
      } else if ("postalCode".equalsIgnoreCase(str)) {
        scopes.add(ProfileScope.postalCode());
      } else {
        scopes.add(ScopeFactory.scopeNamed(str));
      }
    }

    return scopes;
  }

  private final StreamHandler userStreamHandler =
      new StreamHandler() {
        @Override
        public void onListen(Object o, EventSink eventSink) {
          userStreamEventSink = eventSink;
        }

        @Override
        public void onCancel(Object o) {
          userStreamEventSink = null;
        }
      };

  private final StreamHandler authorizationStreamHandler =
      new StreamHandler() {
        @Override
        public void onListen(Object o, EventSink eventSink) {
          authorizationEventSink = eventSink;
        }

        @Override
        public void onCancel(Object o) {
          authorizationEventSink = null;
        }
      };
}
