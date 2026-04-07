(function() {
    const MetaData = {
        ElementName: "TextLabel",
        ElementProperties: {
            Size: { X: 100, Y: 100 },
            Position: { X: 50, Y: 50 },
            BackgroundColor3: "#2d2d2d",
            BackgroundTransparency: 0,
            Text: "TextLabel",
            TextSize: 14,
            TextColor: "#ffffff"
        },
        Init: (dom, props) => {
            dom.style.position = 'absolute';
            dom.style.width = props.Size.X + 'px';
            dom.style.height = props.Size.Y + 'px';
            dom.style.left = props.Position.X + 'px';
            dom.style.top = props.Position.Y + 'px';
            dom.style.backgroundColor = props.BackgroundColor3;
            dom.style.opacity = 1 - props.BackgroundTransparency;
            dom.style.display = 'flex';
            dom.style.alignItems = 'center';
            dom.style.justifyContent = 'center';
            dom.style.fontSize = props.TextSize + 'px';
            dom.style.color = props.TextColor;
            dom.style.fontFamily = 'Arial, sans-serif';
            dom.innerText = props.Text;
            console.log("TextLabel initialized", props);
        }
    };

    if (!window.Registry) window.Registry = {};
    window.Registry[MetaData.ElementName] = MetaData;
})();