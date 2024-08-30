# certificateTool

### How to install root trusted certificate via SSH ?

I already read that SecTrustSettingsSetTrustSettings requires user interaction.
That mean that it requires user login and password be entered.

But is it possible to move that authetification to command line, outside UI session?

I made a sample tool that try to do this.

Accordingly to the documentation:
https://developer.apple.com/library/archive/documentation/Security/Conceptual/authorization_concepts/02authconcepts/authconcepts.html#//apple_ref/doc/uid/TP30000995-CH205-CJBJBGAA

>If the timeout attribute is missing, the credential can be used to grant the right as long as the login session lasts, unless the credential is explicitly destroyed.

When I call function AuthorizationCopyRights,
I create a shared credential (login+password).

Authorization rule com.apple.trust-settings.admin does not have timeout attribute.

```
security authorizationdb read com.apple.trust-settings.admin

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>class</key>
	<string>rule</string>
	<key>comment</key>
	<string>For modifying Trust Settings in the Admin domain. Requires entitlement or admin authentication.</string>
	<key>created</key>
	<real>745942864.47938299</real>
	<key>k-of-n</key>
	<integer>1</integer>
	<key>modified</key>
	<real>745942864.47938299</real>
	<key>rule</key>
	<array>
		<string>entitled</string>
		<string>authenticate-admin</string>
	</array>
	<key>version</key>
	<integer>1</integer>
</dict>
</plist>

```


But. If read authd log, when running this tool, in logs we can read this:

```
default	18:28:43.117724+0300	authd	Validating shared credential trustadmin (707) for authenticate-admin (engine 396)
default	18:28:43.117733+0300	authd	credential 707 expired '0.136439 > 0' (does NOT satisfy rule) (engine 396)
```

It says that our credential is expired.
But it should not be expired because the rule does not have timeout.

In summary, accordingly to documentation, SecTrustSettingsSetTrustSettings should not require authentification, when calling process is running as root. Because, com.apple.trust-settings.admin right rule does not have timeout, and since that root authetification on process call will create shared credential which SecTrustSettingsSetTrustSettings will use.

But in reality the behavior is different.

I found, that on some other macs, that tool works as expected. It adds trust certificate silently.
May be there is some special condition for exactly this roght? May be there is some special preferences, flags or environment variables?

### Steps To Reproduce

Change this constants in code before build.

```
const char *userLogin = "your-adminuser";
const char *userPass = "your-password";
const char *certificateName = "your-certificateFileName";
```

You may use testCertificate, or create our own.

1. Build project.
2. Connect to localhost by ssh
```
ssh <youruser>@localhost
```
3. Go to build folder.
4. sudo ./certificateTool

Actual result:
The tool returns:
SecTrustSettingsSetTrustSettings failure. Error: -60007

That means that user interaction is required.

Expected result:
User interaction does not required.
