const SnappingEngine = {
    startDrag(e, id) {
        const obj = window.App.objects[id];
        if (!obj || !obj.dom) return;

        const el = obj.dom;
        const parent = el.parentElement;
        
        // Получаем текущую позицию в момент начала драга
        let currentLeft = el.offsetLeft;
        let currentTop = el.offsetTop;
        
        const children = this.getChildren(id);
        
        const gv = document.getElementById('g-v');
        const gh = document.getElementById('g-h');

        let lastX = e.clientX;
        let lastY = e.clientY;
        let isDragging = false;

        const move = (ev) => {
            isDragging = true;
            const zoom = window.App.zoom || 1;
            
            // Вычисляем смещение от последнего положения мыши
            const dx = (ev.clientX - lastX) / zoom;
            const dy = (ev.clientY - lastY) / zoom;

            // Новая позиция = текущая позиция + смещение
            let newLeft = currentLeft + dx;
            let newTop = currentTop + dy;

            // Примагничивание
            const snapDist = 1;
            if (gv) gv.style.display = 'none';
            if (gh) gh.style.display = 'none';

            const parentWidth = parent.clientWidth;
            const parentHeight = parent.clientHeight;
            const elWidth = el.offsetWidth;
            const elHeight = el.offsetHeight;

            const targetsX = [0, (parentWidth - elWidth) / 2, parentWidth - elWidth];
            const targetsY = [0, (parentHeight - elHeight) / 2, parentHeight - elHeight];

            let snappedX = false;
            let snappedY = false;

            targetsX.forEach((t, i) => {
                if (Math.abs(newLeft - t) < snapDist) {
                    newLeft = t;
                    snappedX = true;
                    if (gv) {
                        gv.style.display = 'block';
                        gv.style.left = (i === 0 ? "0%" : (i === 1 ? "50%" : "100%"));
                    }
                }
            });

            targetsY.forEach((t, i) => {
                if (Math.abs(newTop - t) < snapDist) {
                    newTop = t;
                    snappedY = true;
                    if (gh) {
                        gh.style.display = 'block';
                        gh.style.top = (i === 0 ? "0%" : (i === 1 ? "50%" : "100%"));
                    }
                }
            });

            // Применяем новую позицию
            el.style.left = newLeft + 'px';
            el.style.top = newTop + 'px';
            
            // Обновляем текущую позицию для следующего шага
            currentLeft = newLeft;
            currentTop = newTop;
            
            // Перемещаем детей (сохраняя их относительную позицию)
            const deltaX = newLeft - currentLeft;
            const deltaY = newTop - currentTop;
            
            if (Math.abs(deltaX) > 0.1 || Math.abs(deltaY) > 0.1) {
                children.forEach(childId => {
                    const childObj = window.App.objects[childId];
                    if (childObj && childObj.dom) {
                        const childLeft = parseFloat(childObj.dom.style.left) || 0;
                        const childTop = parseFloat(childObj.dom.style.top) || 0;
                        childObj.dom.style.left = (childLeft + deltaX) + 'px';
                        childObj.dom.style.top = (childTop + deltaY) + 'px';
                    }
                });
            }

            // Обновляем последние координаты мыши
            lastX = ev.clientX;
            lastY = ev.clientY;
        };

        const stop = () => {
            window.removeEventListener('mousemove', move);
            window.removeEventListener('mouseup', stop);
            
            if (gv) gv.style.display = 'none';
            if (gh) gh.style.display = 'none';
            
            if (isDragging) {
                // Сохраняем финальную позицию в props
                if (!obj.props.Position) obj.props.Position = {};
                obj.props.Position.X = currentLeft;
                obj.props.Position.Y = currentTop;
                
                // Обновляем Properties один раз после драга
                if (window.PropertiesEngine) {
                    window.PropertiesEngine.render();
                }
                console.log(`✅ ${obj.name} перемещен на (${currentLeft}, ${currentTop})`);
            }
        };

        window.addEventListener('mousemove', move);
        window.addEventListener('mouseup', stop);
    },
    
    getChildren(parentId) {
        const children = [];
        const findChildren = (pid) => {
            Object.keys(window.App.objects).forEach(id => {
                const obj = window.App.objects[id];
                if (obj && obj.parent === pid && !obj.isEffect) {
                    children.push(id);
                    findChildren(id);
                }
            });
        };
        findChildren(parentId);
        return children;
    }
};

window.SnappingEngine = SnappingEngine;