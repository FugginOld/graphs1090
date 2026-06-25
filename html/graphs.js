//*** BEGIN USER DEFINED VARIABLES ***//

// Set the default time frame to use when loading images when the page is first accessed.
// Can be set to 2h, 8h, 24h, 7d, 30d, or 365d.
let timeFrame = '24h';

// Set the page refresh interval in milliseconds.
let refreshInterval = 60000

//*** END USER DEFINED VARIABLES ***//

// Set this to the hostName of the system which is running dump1090.
let hostName = 'localhost';

let usp;
try {
    // let's make this case insensitive
    usp = {
        params: new URLSearchParams(),
        has: function(s) {return this.params.has(s.toLowerCase());},
        get: function(s) {
            let val = this.params.get(s.toLowerCase());
            if (val) {
                // make XSS a bit harder
                val = val.replace(/[<>#&]/g, '');
                //console.log("usp.get(" + s + ") = " + val);
            }
            return val;
        },
        getFloat: function(s) {
            if (!this.params.has(s.toLowerCase())) return null;
            const param =  this.params.get(s.toLowerCase());
            if (!param) return null;
            const val = parseFloat(param);
            if (isNaN(val)) return null;
            return val;
        },
        getInt: function(s)  {
            if (!this.params.has(s.toLowerCase())) return null;
            const param =  this.params.get(s.toLowerCase());
            if (!param) return null;
            const val = parseInt(param, 10);
            if (isNaN(val)) return null;
            return val;
        }
    };
    const inputParams = new URLSearchParams(window.location.search);
    for (const [k, v] of inputParams) {
        usp.params.append(k.toLowerCase(), v);
    }
} catch (error) {
    console.error(error);
    usp = {
        has: function() {return false;},
        get: function() {return null;},
    }
}

if (usp.get('refreshInterval')) {
    refreshInterval = usp.get('refreshInterval') * 1000;
}

if (usp.get('timeframe')) {
    timeFrame = usp.get('timeframe');
}

//*** DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING ***//

// ── Theme handling ──────────────────────────────────────────────────────────
// Graphs are rendered per theme into graphs/<theme>/ . The page swaps the image
// folder (and its own chrome via the data-theme attribute) to switch theme.
const THEME_META = [
    { id:'orig-light', name:'Original · Light', sw:'#32CD32' },
    { id:'orig-dark',  name:'Original · Dark',  sw:'#386619' },
    { id:'aviation',   name:'Aviation',         sw:'#4ade80' },
    { id:'minimal',    name:'Minimal',          sw:'#16a34a' },
    { id:'night',      name:'Night',            sw:'#818cf8' },
    { id:'retro',      name:'Retro',            sw:'#5db329' },
];
const DEFAULT_THEME = 'night';
let theme = DEFAULT_THEME;
let graphDir = 'graphs/' + theme + '/';

try {
    const stored = localStorage.getItem('graphs1090_theme');
    if (stored) theme = stored;
} catch (e) {}
if (usp.get('theme')) theme = usp.get('theme');

function applyChrome() {
    document.body.setAttribute('data-theme', theme);
    document.querySelectorAll('#theme-group .btn').forEach(b =>
        b.classList.toggle('active', b.dataset.id === theme));
}

function setTheme(newTheme) {
    if (newTheme) theme = newTheme;
    try { localStorage.setItem('graphs1090_theme', theme); } catch (e) {}
    applyChrome();
    switchView();   // reloads every image from graphs/<theme>/
}

// Build the theme switcher; restrict to themes actually generated (themes.json),
// falling back to the full list if the manifest is unavailable.
function buildThemeSwitcher(available) {
    const group = document.getElementById('theme-group');
    if (!group) return;
    group.innerHTML = '';
    const metas = THEME_META.filter(m => !available || available.includes(m.id));
    if (available && !available.includes(theme)) theme = metas.length ? metas[0].id : theme;
    metas.forEach(m => {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'btn theme-btn';
        b.dataset.id = m.id;
        b.innerHTML = '<span class="sw" style="background:' + m.sw + '"></span>' + m.name;
        b.onclick = () => setTheme(m.id);
        group.appendChild(b);
    });
    applyChrome();
}

fetch('graphs/themes.json')
    .then(r => r.json())
    .then(list => buildThemeSwitcher(list))
    .catch(() => buildThemeSwitcher(null));

const MANIFEST_PANELS = {
    'dump978':       'panel_978',
    'airspy':        'panel_airspy',
    'dump1090-misc': 'dump1090-misc-link',
};

fetch('graphs/manifest.json')
    .then(r => r.json())
    .then(active => {
        active.forEach(key => {
            const id = MANIFEST_PANELS[key];
            if (id) {
                const el = document.getElementById(id);
                if (el) el.style.display = '';
            }
        });
    })
    .catch(() => {});


function switchView(newTimeFrame) {
    clearTimeout(refreshTimer);
    refreshTimer = setTimeout(switchView, refreshInterval);

    if (newTimeFrame) {
        timeFrame = newTimeFrame;
    }

    // Active theme folder for all image paths this pass.
    graphDir = 'graphs/' + theme + '/';

    // Refresh the sidebar "Now" stats alongside the graphs.
    updateSidebar();

    // Set the timestamp variable to be used in querystring.
    $timestamp = Math.round(new Date().getTime() / 1000 / 15) * 15;

    // Display images for the requested time frame and create links to full sized images for the requested time frame.
    var element;
    $("#dump1090-local_trailing_rate-image").attr("src", graphDir + "dump1090-" + hostName + "-local_trailing_rate-" + timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-local_trailing_rate-link").attr("href", graphDir + "dump1090-" + hostName + "-local_trailing_rate-" + timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-local_rate-image").attr("src", graphDir + "dump1090-" + hostName + "-local_rate-" + timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-local_rate-link").attr("href", graphDir + "dump1090-" + hostName + "-local_rate-" + timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-aircraft_message_rate-image").attr("src", graphDir + "dump1090-" + hostName + "-aircraft_message_rate-" + timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-aircraft_message_rate-link").attr("href", graphDir + "dump1090-" + hostName + "-aircraft_message_rate-" + timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-aircraft-image").attr("src", graphDir + "dump1090-" + hostName + "-aircraft-" + timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-aircraft-link").attr("href", graphDir + "dump1090-" + hostName + "-aircraft-" + timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-tracks-image").attr("src", graphDir + "dump1090-" + hostName + "-tracks-" + timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-tracks-link").attr("href", graphDir + "dump1090-" + hostName + "-tracks-" + timeFrame + ".png?time=" + $timestamp);

    element =  document.getElementById('dump1090-range-image');
    if (typeof(element) != 'undefined' && element != null) {
        $("#dump1090-range-image").attr("src", graphDir + "dump1090-" + hostName + "-range-" + timeFrame + ".png?time=" + $timestamp);
        $("#dump1090-range-link").attr("href", graphDir + "dump1090-" + hostName + "-range-" + timeFrame + ".png?time=" + $timestamp);
    }

    element =  document.getElementById('dump1090-range_imperial_statute-image');
    if (typeof(element) != 'undefined' && element != null) {
        $("#dump1090-range_imperial_statute-image").attr("src", graphDir + "dump1090-" + hostName + "-range_imperial_statute-" + timeFrame + ".png?time=" + $timestamp);
        $("#dump1090-range_imperial_statute-link").attr("href", graphDir + "dump1090-" + hostName + "-range_imperial_statute-" + timeFrame + ".png?time=" + $timestamp);
    }

    element =  document.getElementById('dump1090-range_metric-image');
    if (typeof(element) != 'undefined' && element != null) {
        $("#dump1090-range_metric-image").attr("src", graphDir + "dump1090-" + hostName + "-range_metric-" + timeFrame + ".png?time=" + $timestamp);
        $("#dump1090-range_metric-link").attr("href", graphDir + "dump1090-" + hostName + "-range_metric-" + timeFrame + ".png?time=" + $timestamp);
    }

    $("#dump1090-signal-image").attr("src", graphDir + "dump1090-" + hostName + "-signal-" + timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-signal-link").attr("href", graphDir + "dump1090-" + hostName + "-signal-" + timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-cpu-image").attr("src", graphDir + "dump1090-" + hostName + "-cpu-" + timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-cpu-link").attr("href", graphDir + "dump1090-" + hostName + "-cpu-" + timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-misc-image").attr("src", graphDir + "dump1090-" + hostName + "-misc-" + timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-misc-link").attr("href", graphDir + "dump1090-" + hostName + "-misc-" + timeFrame + ".png?time=" + $timestamp);

    if ($("#panel_airspy").css("display") !== "none") {
        $("#airspy-rssi-image").attr("src", graphDir + "airspy-" + hostName + "-rssi-" + timeFrame + ".png?time=" + $timestamp);
        $("#airspy-rssi-link").attr("href", graphDir + "airspy-" + hostName + "-rssi-" + timeFrame + ".png?time=" + $timestamp);

        $("#airspy-snr-image").attr("src", graphDir + "airspy-" + hostName + "-snr-" + timeFrame + ".png?time=" + $timestamp);
        $("#airspy-snr-link").attr("href", graphDir + "airspy-" + hostName + "-snr-" + timeFrame + ".png?time=" + $timestamp);

        $("#airspy-noise-image").attr("src", graphDir + "airspy-" + hostName + "-noise-" + timeFrame + ".png?time=" + $timestamp);
        $("#airspy-noise-link").attr("href", graphDir + "airspy-" + hostName + "-noise-" + timeFrame + ".png?time=" + $timestamp);

        $("#airspy-misc-image").attr("src", graphDir + "airspy-" + hostName + "-misc-" + timeFrame + ".png?time=" + $timestamp);
        $("#airspy-misc-link").attr("href", graphDir + "airspy-" + hostName + "-misc-" + timeFrame + ".png?time=" + $timestamp);

        $("#df_counts-image").attr("src", graphDir + "df_counts-" + hostName + "-" + timeFrame + ".png?time=" + $timestamp);
        $("#df_counts-link").attr("href", graphDir + "df_counts-" + hostName + "-" + timeFrame + ".png?time=" + $timestamp);
    }

    if ($("#panel_978").css("display") !== "none") {
        $("#dump1090-aircraft_978-image").attr("src", graphDir + "dump1090-" + hostName + "-aircraft_978-" + timeFrame + ".png?time=" + $timestamp);
        $("#dump1090-aircraft_978-link").attr("href", graphDir + "dump1090-" + hostName + "-aircraft_978-" + timeFrame + ".png?time=" + $timestamp);

        $("#dump1090-range_978-image").attr("src", graphDir + "dump1090-" + hostName + "-range_978-" + timeFrame + ".png?time=" + $timestamp);
        $("#dump1090-range_978-link").attr("href", graphDir + "dump1090-" + hostName + "-range_978-" + timeFrame + ".png?time=" + $timestamp);

        $("#dump1090-messages_978-image").attr("src", graphDir + "dump1090-" + hostName + "-messages_978-" + timeFrame + ".png?time=" + $timestamp);
        $("#dump1090-messages_978-link").attr("href", graphDir + "dump1090-" + hostName + "-messages_978-" + timeFrame + ".png?time=" + $timestamp);

        $("#dump1090-signal_978-image").attr("src", graphDir + "dump1090-" + hostName + "-signal_978-" + timeFrame + ".png?time=" + $timestamp);
        $("#dump1090-signal_978-link").attr("href", graphDir + "dump1090-" + hostName + "-signal_978-" + timeFrame + ".png?time=" + $timestamp);
    }

    if ($("#panel_system").css("display") !== "none") {
        $("#system-cpu-image").attr("src", graphDir + "system-" + hostName + "-cpu-" + timeFrame + ".png?time=" + $timestamp);
        $("#system-cpu-link").attr("href", graphDir + "system-" + hostName + "-cpu-" + timeFrame + ".png?time=" + $timestamp);

        element =  document.getElementById('system-eth0_bandwidth-image');
        if (typeof(element) != 'undefined' && element != null) {
            $("#system-eth0_bandwidth-image").attr("src", graphDir + "system-" + hostName + "-eth0_bandwidth-" + timeFrame + ".png?time=" + $timestamp);
            $("#system-eth0_bandwidth-link").attr("href", graphDir + "system-" + hostName + "-eth0_bandwidth-" + timeFrame + ".png?time=" + $timestamp);
        }
        element =  document.getElementById('system-network_bandwidth-image');
        if (typeof(element) != 'undefined' && element != null) {
            $("#system-network_bandwidth-image").attr("src", graphDir + "system-" + hostName + "-network_bandwidth-" + timeFrame + ".png?time=" + $timestamp);
            $("#system-network_bandwidth-link").attr("href", graphDir + "system-" + hostName + "-network_bandwidth-" + timeFrame + ".png?time=" + $timestamp);
        }

        $("#system-memory-image").attr("src", graphDir + "system-" + hostName + "-memory-" + timeFrame + ".png?time=" + $timestamp);
        $("#system-memory-link").attr("href", graphDir + "system-" + hostName + "-memory-" + timeFrame + ".png?time=" + $timestamp);

        element =  document.getElementById('system-temperature_imperial-image');
        if (typeof(element) != 'undefined' && element != null) {
            $("#system-temperature_imperial-image").attr("src", graphDir + "system-" + hostName + "-temperature_imperial-" + timeFrame + ".png?time=" + $timestamp);
            $("#system-temperature_imperial-link").attr("href", graphDir + "system-" + hostName + "-temperature_imperial-" + timeFrame + ".png?time=" + $timestamp);
        }
        element =  document.getElementById('system-temperature-image');
        if (typeof(element) != 'undefined' && element != null) {
            $("#system-temperature-image").attr("src", graphDir + "system-" + hostName + "-temperature-" + timeFrame + ".png?time=" + $timestamp);
            $("#system-temperature-link").attr("href", graphDir + "system-" + hostName + "-temperature-" + timeFrame + ".png?time=" + $timestamp);
        }

        $("#system-df_root-image").attr("src", graphDir + "system-" + hostName + "-df_root-" + timeFrame + ".png?time=" + $timestamp);
        $("#system-df_root-link").attr("href", graphDir + "system-" + hostName + "-df_root-" + timeFrame + ".png?time=" + $timestamp);

        $("#system-disk_io_iops-image").attr("src", graphDir + "system-" + hostName + "-disk_io_iops-" + timeFrame + ".png?time=" + $timestamp);
        $("#system-disk_io_iops-link").attr("href", graphDir + "system-" + hostName + "-disk_io_iops-" + timeFrame + ".png?time=" + $timestamp);

        $("#system-disk_io_octets-image").attr("src", graphDir + "system-" + hostName + "-disk_io_octets-" + timeFrame + ".png?time=" + $timestamp);
        $("#system-disk_io_octets-link").attr("href", graphDir + "system-" + hostName + "-disk_io_octets-" + timeFrame + ".png?time=" + $timestamp);
    }
    // Set the button related to the selected time frame to active.
    $("#btn-2h").removeClass('active');
    $("#btn-8h").removeClass('active');
    $("#btn-24h").removeClass('active');
    $("#btn-48h").removeClass('active');
    $("#btn-7d").removeClass('active');
    $("#btn-14d").removeClass('active');
    $("#btn-30d").removeClass('active');
    $("#btn-90d").removeClass('active');
    $("#btn-180d").removeClass('active');
    $("#btn-365d").removeClass('active');
    $("#btn-730d").removeClass('active');
    $("#btn-1095d").removeClass('active');
    $("#btn-1825d").removeClass('active');
    $("#btn-3650d").removeClass('active');
    $("#btn-" + timeFrame).addClass('active');


    let pathName = window.location.pathname.replace(/\/+/, '/') || "/";
    let url = window.location.origin + pathName + "?timeframe=" + timeFrame;
    window.history.replaceState("object or string", "Title", url);
}

let verbose = true;
let refreshTimer = null;
let timersActive = false;

function handleVisibilityChange() {
    if (document.hidden && timersActive) {
        verbose && console.log(new Date().toLocaleTimeString() + " visibility change: stopping timers");
        clearTimeout(refreshTimer);
        timersActive = false;
    }
    if (!document.hidden && !timersActive) {
        verbose && console.log(new Date().toLocaleTimeString() + " visibility change: starting timers");
        timersActive = true;
        // Display the images for the supplied time frame. (starts refreshTimer)
        switchView();
    }
}

// Warn if the browser doesn't support addEventListener or the Page Visibility API
if (typeof document.addEventListener === "undefined" || document.hidden === undefined) {
    console.error("hidden tab handler requires a browser that supports the Page Visibility API.");
} else {
    document.addEventListener("visibilitychange", handleVisibilityChange, false);
}

// start the timer stuff
handleVisibilityChange();


const cursorVT = document.querySelector('.vt')
const cursorHL = document.querySelector('.hl')

function crosshairListener(e) {
    cursorVT.setAttribute('style', `left: ${e.clientX}px;`)
    cursorHL.setAttribute('style', `top: ${e.clientY}px;`)
}

let crosshair = false;
function toggleCrosshair() {
    crosshair = !crosshair;
    if (crosshair) {
        document.addEventListener('mousemove', crosshairListener);
        $("#crosshair").show();
    } else {
        document.removeEventListener('mousemove', crosshairListener);
        $("#crosshair").hide();
    }
}

// ── Sidebar "Now" stats (from graphs/stats.json) ────────────────────────────
function setText(id, val) { const el = document.getElementById(id); if (el) el.textContent = val; }
function setBar(id, pct) {
    const el = document.getElementById(id);
    if (el) el.style.width = Math.max(0, Math.min(100, pct)) + '%';
}
function num(v, d) { return (v === null || v === undefined || isNaN(v)) ? '—' : Number(v).toFixed(d === undefined ? 0 : d); }

function updateSidebar() {
    fetch('graphs/stats.json?t=' + Math.round(Date.now() / 15000))
        .then(r => r.json())
        .then(s => {
            const ac = s.aircraft || {}, rng = s.range || {}, sig = s.signal || {}, sys = s.system || {};

            setText('st-aircraft', num(ac.total));
            const sub = [];
            if (ac.positions != null) sub.push(ac.positions + ' w/ pos');
            if (ac.mlat != null) sub.push(ac.mlat + ' mlat');
            if (ac.tisb != null) sub.push(ac.tisb + ' tisb');
            setText('st-aircraft-sub', sub.join(' · '));
            setBar('st-aircraft-bar', (ac.total || 0) / 250 * 100);

            setText('st-range', num(rng.max_nmi, 1));
            setText('st-range-sub', rng.median_nmi != null ? ('median ' + num(rng.median_nmi, 1)) : '');
            setBar('st-range-bar', (rng.max_nmi || 0) / 300 * 100);

            setText('st-signal', num(sig.median, 1));
            setText('st-signal-sub', sig.peak != null ? ('peak ' + num(sig.peak, 1)) : '');
            setBar('st-signal-bar', sig.median != null ? (sig.median + 50) / 50 * 100 : 0);

            setText('st-msgrate', num(s.message_rate, 1));

            setText('st-cpu', num(sys.cpu, 1));
            setBar('st-cpu-bar', sys.cpu || 0);

            setText('st-temp', num(sys.temp_c, 1));
            setBar('st-temp-bar', sys.temp_c != null ? (sys.temp_c - 20) / 60 * 100 : 0);

            const MB = 1024 * 1024, GB = 1024 * 1024 * 1024;
            if (sys.mem_used != null) {
                const total = (sys.mem_used || 0) + (sys.mem_free || 0) + (sys.mem_cached || 0);
                setText('st-mem', num(sys.mem_used / MB));
                setText('st-mem-sub', total ? ('of ' + num(total / MB) + ' MB · ' + Math.round(sys.mem_used / total * 100) + '%') : '');
                setBar('st-mem-bar', total ? sys.mem_used / total * 100 : 0);
            }
            if (sys.disk_used != null) {
                const total = (sys.disk_used || 0) + (sys.disk_free || 0);
                setText('st-disk', num(sys.disk_used / GB, 1));
                setText('st-disk-sub', total ? ('of ' + num(total / GB, 1) + ' GB · ' + Math.round(sys.disk_used / total * 100) + '%') : '');
                setBar('st-disk-bar', total ? sys.disk_used / total * 100 : 0);
            }

            if (s.updated) {
                const d = new Date(s.updated * 1000);
                setText('st-updated', 'Updated · ' + d.toLocaleTimeString());
            }
        })
        .catch(() => {});
}
