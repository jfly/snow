var done = false; //<<<

var observer = new MutationObserver(function(mutations) {
    var dropdownMenu = document.querySelector(".dropdown-menu");
    if(dropdownMenu) {
        if(!done) {
            console.log("something changed on the page");
            console.log(dropdownMenu);
            var li = document.createElement('li');
            li.appendChild(document.createTextNode("Play in MPlayer"));
            dropdownMenu.appendChild(li);
            done = true;//<<<
        }
    }
});

observer.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: false,
    characterData: false,
});
