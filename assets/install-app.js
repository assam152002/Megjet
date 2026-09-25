(function(){
  "use strict";
  const button=document.getElementById("megjetInstall");
  const help=document.getElementById("megjetInstallHelp");
  if(!button||!help)return;
  let installPrompt=null;
  const installed=()=>window.matchMedia("(display-mode: standalone)").matches||navigator.standalone===true;
  const turkish=()=>document.documentElement.lang==="tr";
  function update(){
    button.hidden=installed();
    button.textContent=turkish()?"⬇ Uygulamayı Yükle":"⬇ Install App";
    if(installed())help.hidden=true;
  }
  window.addEventListener("beforeinstallprompt",event=>{
    event.preventDefault();
    installPrompt=event;
    update();
  });
  window.addEventListener("appinstalled",()=>{installPrompt=null;update()});
  window.addEventListener("megjet:languagechange",update);
  window.matchMedia("(display-mode: standalone)").addEventListener?.("change",update);
  button.addEventListener("click",async()=>{
    if(installPrompt){
      const event=installPrompt;
      installPrompt=null;
      help.hidden=true;
      await event.prompt();
      update();
      return;
    }
    const apple=/iPad|iPhone|iPod/.test(navigator.userAgent);
    help.textContent=apple
      ?(turkish()?"Safari'de Paylaş düğmesine dokunun, ardından Ana Ekrana Ekle'yi seçin.":"In Safari, tap Share, then Add to Home Screen.")
      :(turkish()?"Tarayıcı menüsünü açıp Uygulamayı yükle veya Ana ekrana ekle seçeneğini seçin.":"Open your browser menu and choose Install app or Add to Home Screen.");
    help.hidden=false;
  });
  update();
})();
