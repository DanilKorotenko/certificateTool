//
//  main.m
//  certificateTool
//
//  Created by Danil Korotenko on 8/22/24.
//

#import <Foundation/Foundation.h>

SecCertificateRef openCertificate(NSString *aPath)
{
    NSURL *url = [NSURL fileURLWithPath:aPath isDirectory:NO];
    NSData *certData = [NSData dataWithContentsOfURL:url];

    CFDataRef certDataRef = (__bridge CFDataRef)(certData);

    SecCertificateRef result = SecCertificateCreateWithData(NULL, certDataRef);

    return result;
}

const char *userLogin = "trustadmin";
const char *userPass = "pass123456";
const char *certificateName = "testCertificate.der";

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        SecCertificateRef certificate = openCertificate(@(certificateName));
        if (!certificate)
        {
            return 0;
        }

        SecKeychainRef keychain = NULL;
        SecKeychainCopyDomainDefault(kSecPreferencesDomainSystem, &keychain);
        if (!keychain)
        {
            return 0;
        }

        SecCertificateAddToKeychain(certificate, keychain);

        AuthorizationRef myAuthorizationRef = NULL;
        OSStatus myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,
            kAuthorizationFlagDefaults, &myAuthorizationRef);

        AuthorizationItem myItems[1];

        myItems[0].name = "com.apple.trust-settings.admin";
        myItems[0].valueLength = 0;
        myItems[0].value = NULL;
        myItems[0].flags = 0;

        AuthorizationRights myRights;
        myRights.count = sizeof (myItems) / sizeof (myItems[0]);
        myRights.items = myItems;

        AuthorizationFlags myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights;

        AuthorizationItem authenv[] =
        {
            { kAuthorizationEnvironmentUsername, strlen(userLogin), (void *)userLogin, 0 },
            { kAuthorizationEnvironmentPassword, strlen(userPass), (void *)userPass, 0 },
            { kAuthorizationEnvironmentShared, 0, NULL, 0 }
        };

        AuthorizationEnvironment env = { 3, authenv };

        AuthorizationRights *myAuthorizedRights = NULL;
        myStatus = AuthorizationCopyRights(myAuthorizationRef, &myRights,
            &env, myFlags, &myAuthorizedRights);


        OSStatus err = SecTrustSettingsSetTrustSettings(certificate, kSecTrustSettingsDomainAdmin, NULL);
        if (err != noErr)
        {
            NSLog(@"SecTrustSettingsSetTrustSettings failure. Error: %d", err);
        }



        if (myAuthorizedRights)
        {
            AuthorizationFreeItemSet (myAuthorizedRights);
        }
        AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDestroyRights);

        CFRelease(keychain);
        CFRelease(certificate);
    }
    return 0;
}
