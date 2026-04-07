(function() {
    const MetaData = {
        ElementName: "ImageLabel",
        ElementProperties: {
            Size: "100, 100",
            Image: "",
            BackgroundColor3: "#cccccc"
        },
        Init: (dom) => {
            dom.style.backgroundImage = "url('https://via.placeholder.com/100')";
            dom.style.backgroundSize = "cover";
            dom.style.backgroundColor = "#ccc";
        }
    };

    if (!window.Registry) window.Registry = {};
    window.Registry[MetaData.ElementName] = MetaData;
})();