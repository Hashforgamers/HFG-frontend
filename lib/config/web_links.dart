/// Host for shareable links. Only www serves the app-link association files
/// directly; the apex and .co.in domains redirect, which breaks verification
/// on both iOS and Android, so links on them open the browser instead.
const kWebHost = 'www.hashforgamers.com';
const kWebOrigin = 'https://$kWebHost';
