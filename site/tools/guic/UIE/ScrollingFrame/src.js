(function() {
    const MetaData = {
        ElementName: "ScrollingFrame",
        
        // Список доступных свойств и их начальные значения
        ElementProperties: {
            Size: { X: 200, Y: 200 },
            Position: { X: 50, Y: 50 },
            BackgroundColor3: "#2a2a2a",
            BackgroundTransparency: 0,
            ScrollBarThickness: 6,
            CanvasSize: "0, 0, 2, 0",
            ClipsDescendants: true
        },

        // Специфические функции (например, что делать при создании)
        Init: (dom, props) => {
            dom.style.position = 'absolute';
            dom.style.width = props.Size.X + 'px';
            dom.style.height = props.Size.Y + 'px';
            dom.style.left = props.Position.X + 'px';
            dom.style.top = props.Position.Y + 'px';

            const r = parseInt(props.BackgroundColor3.slice(1,3), 16);
            const g = parseInt(props.BackgroundColor3.slice(3,5), 16);
            const b = parseInt(props.BackgroundColor3.slice(5,7), 16);
            dom.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${1 - props.BackgroundTransparency})`;

            dom.style.border = 'none';
            dom.style.boxSizing = 'border-box';
            dom.style.overflowY = "scroll";
            dom.style.overflowX = "hidden";
            dom.style.display = "block";
            
            // Стили scrollbar
            const sbWidth = props.ScrollBarThickness || 6;
            dom.style.setProperty('--sb-width', sbWidth + "px");
            
            console.log(`${MetaData.ElementName} инициализирован!`, props);
        },

        // Функция, которая срабатывает при изменении любого свойства
        OnPropertyChanged: (dom, prop, value) => {
            if (prop === "ScrollBarThickness") {
                // Тут можно менять ширину полосы прокрутки через CSS переменные
                dom.style.setProperty('--sb-width', value + "px");
            }
        }
    };

    // Регистрируем этот объект в глобальный реестр
    if (!window.Registry) window.Registry = {};
    window.Registry[MetaData.ElementName] = MetaData;
})();