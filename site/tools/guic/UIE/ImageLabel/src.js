(function() {
    const MetaData = {
        ElementName: "ImageLabel",
        ElementProperties: {
            Size: { X: 100, Y: 100 },
            Position: { X: 50, Y: 50 },
            Image: "",
            BackgroundColor3: "#cccccc",
            BackgroundTransparency: 0,
            ClipsDescendants: false
        },
        Init: (dom, props) => {
            dom.style.position = 'absolute';
            dom.style.width = props.Size.X + 'px';
            dom.style.height = props.Size.Y + 'px';
            dom.style.left = props.Position.X + 'px';
            dom.style.top = props.Position.Y + 'px';
            dom.style.border = 'none';
            dom.style.boxSizing = 'border-box';
            dom.style.overflow = props.ClipsDescendants ? 'hidden' : 'visible';

            const r = parseInt(props.BackgroundColor3.slice(1,3), 16);
            const g = parseInt(props.BackgroundColor3.slice(3,5), 16);
            const b = parseInt(props.BackgroundColor3.slice(5,7), 16);
            dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - props.BackgroundTransparency})`;
            
            // Обработка изображения
            if (props.Image && props.Image.trim() !== '') {
                // Если начинается с rbxasset:// или http, используем как URL
                // Если это Base64, используем data:image
                let imageUrl = props.Image;
                if (props.Image.startsWith('data:image') || 
                    props.Image.startsWith('http://') || 
                    props.Image.startsWith('https://') ||
                    props.Image.startsWith('rbxasset://')) {
                    imageUrl = props.Image;
                } else if (props.Image.length > 50 && !props.Image.includes(' ')) {
                    // Вероятно Base64
                    imageUrl = `data:image/png;base64,${props.Image}`;
                }
                dom.style.backgroundImage = `url('${imageUrl}')`;
                dom.style.backgroundSize = "cover";
                dom.style.backgroundPosition = "center";
            } else {
                // Placeholder если картинки нет
                dom.style.backgroundImage = "url('https://via.placeholder.com/100')";
                dom.style.backgroundSize = "cover";
            }
            
            console.log("ImageLabel initialized", props);
        }
    };

    if (!window.Registry) window.Registry = {};
    window.Registry[MetaData.ElementName] = MetaData;
})();