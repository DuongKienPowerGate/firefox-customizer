#!/bin/bash

# Addons
#
addons=(
  # Adblock Plus
  1865
  # Adblock Plus Pop-up Addon
  83098
  # Classic Theme Restorer
  472577
  # Disconnect
  464050
  # DuckDuckGo Plus
  385621
  # RedirectCleaner
  601248
  # Status-4-Evar
  235283
)

# Preferences (prefs.js)
#
preferences=(
  # Disable to send health report
  'datareporting.healthreport.service.firstRun=true'
  'datareporting.healthreport.uploadEnabled=false'
  # Make about:blank the startpage
  'browser.startup.homepage="about:blank"'
  'browser.startup.page=0'
  # Don't remember passwords
  'signon.rememberSignons=false'
  # Do not track
  'privacy.donottrackheader.enabled=true'
  # Private browsing mode enabled
  'browser.privatebrowsing.autostart=true'
  # No remember histroy in URL bar
  'browser.urlbar.suggest.history=false'
  # No search suggestions in URL bar (also unset in DuckduckGo Addon)
  'browser.search.suggest.enabled=false'
  'extensions.jid1-ZAdIEUB7XOzOJw@jetpack.addressbar_autocomplete=false'
  # New page tab clean
  'browser.newtabpage.enabled=false'
  'browser.newtabpage.enhanced=false'
  'browser.newtabpage.introShown=true'
  # Adblock plus
  'extensions.adblockplus.hideContributeButton=true'
  # Status 4 evar
  'extensions.caligon.s4e.progress.urlbar=0'
  'extensions.caligon.s4e.status.popup.mouseMirror=false'
  # URL stop protocol hide and stop domain highlighting
  'browser.urlbar.formatting.enabled=false'
  'browser.urlbar.trimURLs=false'
  # Classic Theme restorer
  'extensions.classicthemerestorer.aboutprefs="category-advanced"'
  'extensions.classicthemerestorer.am_extrabars=0'
  'extensions.classicthemerestorer.appmenuitem=false'
  'extensions.classicthemerestorer.ctrreset=false'
  'extensions.classicthemerestorer.hideurelstop=true'
  'extensions.classicthemerestorer.hideurlgo=true'
  'extensions.classicthemerestorer.pref_actindx=15'
  'extensions.classicthemerestorer.starinurl=true'
  'extensions.classicthemerestorer.tabs="tabs_default"'
  'extensions.classicthemerestorer.toolsitem=false'
  # Get rid of Pocket
  'browser.pocket.enabled=false'
  # Get rid of Reader
  'reader.parse-on-load.enabled=false'
  # Get rid of Geolocation
  'geo.enabled=false'
)

# Adblock Plus subscriptions
#
adblock_subscriptions=(
  'https://easylist-downloads.adblockplus.org/antiadblockfilters.txt'
  'https://easylist-downloads.adblockplus.org/easylist.txt'
  'https://easylist-downloads.adblockplus.org/easyprivacy.txt'
  'https://easylist-downloads.adblockplus.org/easylistgermany.txt'
  'https://easylist-downloads.adblockplus.org/fanboy-annoyance.txt'
)

# Toolbar content customizations ("browser.uiCustomization.state" in prefs.js)
#
toolbar_content_customizations=(
  'PanelUI-contents=edit-controls,zoom-controls,new-window-button,privatebrowsing-button,save-page-button,print-button,history-panelmenu,fullscreen-button,find-button,preferences-button,add-ons-button'
  'PersonalToolbar=personal-bookmarks,ctraddon_bookmarks-menu-toolbar-button'
  'TabsToolbar=tabbrowser-tabs,new-tab-button,ctraddon_tabs-closebutton'
  'ctraddon_addon-bar=ctraddon_addonbar-close,customizableui-special-spring1'
  'nav-bar=bookmarks-menu-button,ctraddon_back-forward-button,urlbar-container'
  'status4evar-status-bar=status4evar-progress-widget,status4evar-status-widget,status4evar-download-button,developer-button'
)

# Toolbar visibility customizations (xulstore.json)
#
toolbar_visibility_customizations=(
  'ctraddon_addon-bar="collapsed":"true","currentset":"ctraddon_addonbar-close,customizableui-special-spring1,ctraddon_statusbar"'
  'toolbar-menubar="autohide":"false","currentset":"menubar-items"'
)


pid=`ps -e | grep " firefox$" | xargs | cut -d" " -f1`

if [[ -n "$pid" ]]; then
  echo "Firefox is running, please close all instances first!"
  exit 1
fi

mkdir -p build/
cd build/

echo -n "Downloading addons "

for addon in ${addons[@]}; do
  wget -q https://addons.mozilla.org/firefox/downloads/latest/${addon}/addon-${addon}-latest.xpi
  echo -n "."
done

echo " OK"

cat > install.rdf <<_EOF_
<?xml version="1.0" encoding="UTF-8" ?>

<RDF xmlns="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:em="http://www.mozilla.org/2004/em-rdf#">

  <Description about="urn:mozilla:install-manifest">

    <em:id>addonbundle@pimprecords.com</em:id>
    <em:type>32</em:type>

  </Description>

  <!-- Firefox -->
  <em:targetApplication>
    <Description>
      <em:id>{ec8030f7-c20a-464f-9b0e-13a3a9e97384}</em:id>
      <em:minVersion>38.0</em:minVersion>
      <em:maxVersion>99.*</em:maxVersion>
    </Description>
  </em:targetApplication>

</RDF>
_EOF_

echo -n "Creating addon bundle ..."

zip -q bundle.xpi addon-*-latest.xpi install.rdf

echo " OK"

echo -n "Starting Firefox to install addons. Please close it manually after installation ..."

firefox bundle.xpi 2>&1 >/dev/null

echo " OK"

echo -n "Run Firefox again in order to run (annoying) bootstrap code. Please close it manually after boot ..."

firefox 2>&1 >/dev/null

echo " OK"

profile_dir=`echo ~/.mozilla/firefox/*.default/`

echo -n "Updating prefs.js "

file="${profile_dir}prefs.js"

for preference in ${preferences[@]}; do
  parts=(${preference//=/ })
  key=${parts[0]}
  value=${parts[1]}
  sed -i 's/^.*${key}.*$//g' $file
  if [[ -n "$value" ]]; then
    echo "user_pref(\"${key}\", ${value});" >> $file
  fi
  echo -n "."
done

echo " OK"

echo -n "Updating Adblock Plus subscriptions "

rm -f "${profile_dir}adblockplus/elemhide.css"

file="${profile_dir}adblockplus/patterns.ini"

echo "# Adblock Plus preferences" > $file
echo "version=4" >> $file

for subscription in ${adblock_subscriptions[@]}; do
  wget -q -O subscription.txt $subscription
  echo "" >> $file
  echo "[Subscription]" >> $file
  echo "url=${subscription}" >> $file
  title=`grep "! Title:" subscription.txt | cut -d":" -f2 | cut -d"#" -f1 | xargs -0`
  echo "title=${title}" >> $file
  echo "fixedTitle=true" >> $file
  homepage=`grep "! Homepage:" subscription.txt | cut -c13-`
  echo "homepage=${homepage}" >> $file
  now=`date +%s`
  echo "lastDownload=${now}" >> $file
  echo "downloadStatus=synchronize_ok" >> $file
  echo "lastSuccess=${now}" >> $file
  echo "lastCheck=${now}" >> $file
  expire_days=`grep "! Expires:" subscription.txt | cut -c12`
  expire=`date +%s --date "now + ${expire_days} days"`
  echo "expires=${expire}" >> $file
  echo "softExpiration=${expire}" >> $file
  version=`grep "! Version:" subscription.txt | cut -d":" -f2`
  echo "version=${version}" >> $file
  echo "requiredVersion=2.0" >> $file
  echo "downloadCount=1" >> $file
  echo "" >> $file
  echo "[Subscription filters]" >> $file
  tail -n +2 subscription.txt >> $file
  echo -n "."
done

rm -f subscription.txt

echo " OK"

echo -n "Customizing toolbar contents "

file="${profile_dir}prefs.js"

workfile=toolbar.json

grep "browser.uiCustomization.state" $file | sed 's/^.*"browser.uiCustomization.state", "\(.*\)");$/\1/' | sed 's/\\"/"/g' > $workfile

for customization in ${toolbar_content_customizations[@]}; do
  parts=(${customization//=/ })
  name=${parts[0]}
  elements=(${parts[1]//,/ })

  # I somehow didn't manage to look for all characters except "]", therefore
  # using ":", which should be safe as long as there is no further nesting of
  # "placements" items
  sed -i "s/\"${name}\":\[[^:]*\],\?//g" $workfile

  if [[ ${#elements[@]} -gt 0 ]]; then
    element_list=`printf "%s\",\"" "${elements[@]}"`

    toolbar_json="\"${name}\":[\"${element_list%???}\"],"

    sed -i "s/\(\"placements\":{\)/\1${toolbar_json}/" $workfile
  fi
  echo -n "."
done

sed -i "s/,}/}/g" $workfile

customized_json=`sed 's/"/\\\"/g' $workfile`

sed -i 's/^.*browser.uiCustomization.state.*$//g' $file
echo "user_pref(\"browser.uiCustomization.state\", \"${customized_json}\");" >> $file

echo " OK"

echo -n "Updating toolbar visibilities "

file="${profile_dir}xulstore.json"

for customization in ${toolbar_visibility_customizations[@]}; do
  parts=(${customization//=/ })
  name=${parts[0]}
  content=${parts[1]}

  sed -i "s/\"${name}\":{[^}]*},\?//g" $file

  if [[ -n "$content" ]]; then
    toolbar_json="\"${name}\":{${content}},"

    sed -i "s/\(\"chrome:\/\/browser\/content\/browser.xul\":{\)/\1${toolbar_json}/" $file
  fi
  echo -n "."
done

sed -i "s/,}/}/g" $file

echo " OK"

cd ..
rm -rf build/
