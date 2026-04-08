{
const MetaData = {
    ElementName: "ScrollingFrame",
    
    // Список доступных свойств и их начальные значения
    ElementProperties: {
        Size: "200, 200",
        BackgroundColor3: "#2a2a2a",
        BackgroundTransparency: 0,
        ScrollBarThickness: 6,
        CanvasSize: "0, 0, 2, 0"
    },

    // Специфические функции (например, что делать при создании)
    Init: (dom) => {
        dom.style.overflowY = "scroll";
        dom.style.display = "flex";
        console.log(`${MetaData.ElementName} инициализирован!`);
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
}