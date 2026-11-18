# How it works

Goal: explain the requests the script sends, so you can check them or adapt
them to another router.

This describes the behavior verified on the Prolink PRN3002-C. Other models
may use different endpoints, fields, or headers.

## The three steps

The script uses `curl` to send two form posts, then uses `ping` to wait.

1. **Log in.** The script sends:

   ```http
   POST http://<router-ip>/login.cgi
   Referer: http://<router-ip>/login.htm

   username=<user>
   password=<password>
   submit.htm?login.htm=Send
   ```

   The router answers with HTTP 200 and a small page that redirects to
   `index.htm`. It sets no cookie. The router appears to track the logged-in
   client by IP address.

2. **Request the reboot.** The script sends:

   ```http
   POST http://<router-ip>/form2Reboot.cgi
   Referer: http://<router-ip>/reboot.htm

   reboot=Reboot
   submit.htm?reboot.htm=Send
   ```

3. **Wait for it to return.** The script sleeps 10 seconds, then pings the
   router up to 40 times with a 2 second pause. The router showed a 35 second
   countdown in its web interface and answered ping again about 24 seconds
   after the request.

## Why plain form posts work

The router's admin pages are plain HTML forms. They do not require a cookie
or a token that the script has to fetch first. The login page JavaScript
(`onlogin()`) only checks that the username is not empty, and the password is
sent as plain text.

The reboot request is the same request a browser sends when you click the
reboot button. The only difference is that a browser may keep a session
cookie. On this router, the login response sets no cookie, so the script does
not need one.

The router only serves HTTP. The script does not use HTTPS and does not verify
a certificate.

## Adapting to another router

If you have a different router, capture what its web interface sends. You
need the login URL, the reboot URL, the form field names, and any required
headers.

### Read the pages

Replace `<router-ip>` with your router's address. These commands look for
forms, inputs, scripts, and the login function:

```bash
curl -s http://<router-ip>/login.htm | grep -iE "<form|<input|action=|\.js"
```

```bash
curl -s http://<router-ip>/login.htm | grep -n -A15 "function onlogin"
```

```bash
curl -s http://<router-ip>/reboot.htm | sed -n '/id="tab1"/,$p'
```

The output can be large. Look for the form `action` and the `name` of each
input.

### Use the browser

1. Open the router's admin page in a browser.
2. Press F12 to open developer tools.
3. Open the **Network** tab and enable **Preserve log**.
4. Log in, then click the reboot button.
5. Find the login and reboot requests.
6. Right-click a request and choose **Copy as cURL**.

The copied command contains the URL, headers, and form fields. Remove the
password and any cookies before you share it in an issue.

### Change the script

The request details are in the request section of `reboot_router.sh`:

- `LOGIN_URL` and `LOGIN_FIELDS`
- `REBOOT_URL` and `REBOOT_FIELDS`
- The `-e` referer values in the two `curl` calls

Change only what your router needs. Keep the credential lookup and the exit
codes unchanged.

If you get it working, open a
[router compatibility issue](https://github.com/sjnakib/prolink-prn3002c-scheduled-reboot/issues/new?template=router_compatibility.md)
with the model, firmware, and the endpoints that worked. Remove passwords and
cookies first.

If the script does not work on this model, see
[troubleshooting.md](troubleshooting.md).
