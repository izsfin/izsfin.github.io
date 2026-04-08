const Viewport = {
    init() {
        const vport = document.getElementById('vport');
        if (!vport) return;

        // Зум и прокрутка
        vport.addEventListener('wheel', (e) => {
            e.preventDefault();
            if (e.ctrlKey) {
                // Зум
                const delta = e.deltaY > 0 ? 0.9 : 1.1;
                const mX = e.clientX - vport.offsetLeft;
                const mY = e.clientY - vport.offsetTop;

                // Математика зума в точку курсора
                const wX = (mX - App.panX) / App.zoom;
                const wY = (mY - App.panY) / App.zoom;

                App.zoom = Math.max(0.1, Math.min(App.zoom * delta, 10));
                
                App.panX = mX - wX * App.zoom;
                App.panY = mY - wY * App.zoom;
            } else {
                // Обычный скролл (Pan)
                if (e.shiftKey) App.panX -= e.deltaY;
                else App.panY -= e.deltaY;
            }
            this.update();
        }, { passive: false });

        // Панорамирование (Middle Mouse или Space + Left Click)
        let isPanning = false;
        
        vport.addEventListener('mousedown', (e) => {
            // Активируем панорамирование на среднюю кнопку (1) или если нажат фон
            if (e.button === 1 || e.target === vport || e.target.id === 'canvas-origin') {
                isPanning = true;
                vport.style.cursor = 'grabbing';
            }
        });

        window.addEventListener('mousemove', (e) => {
            if (isPanning) {
                App.panX += e.movementX;
                App.panY += e.movementY;
                this.update();
            }
        });

        window.addEventListener('mouseup', () => {
            isPanning = false;
            vport.style.cursor = 'default';
        });

        // Отключаем стандартное меню на среднюю кнопку
        vport.addEventListener('contextmenu', (e) => {
            if (isPanning) e.preventDefault();
        });

        this.update();
    },

    // Метод для визуального обновления трансформации
    update() {
        const canvas = document.getElementById('canvas-origin');
        if (canvas) {
            canvas.style.transform = `translate(${App.panX}px, ${App.panY}px) scale(${App.zoom})`;
        }
    },

    // Вспомогательный метод для динамической привязки перетаскивания (вызывается из UIElements)
    makeDraggable(el) {
        if (!el) return;
        // Здесь можно добавить специфичную логику, если snapping.js не справляется
        // Но обычно достаточно того, что мы уже прописали в UIElements.create
        el.style.pointerEvents = 'auto';
    }
};