/**
 * 压缩HTML内容，移除无关标签和属性
 */
function compress(element) {
    // 移除head、style、script标签
    ['head', 'style', 'script'].forEach(tag => {
        Array.from(element.getElementsByTagName(tag)).forEach(el => el.remove());
    });

    // 移除注释节点
    (function removeComments(node) {
        Array.from(node.childNodes).forEach(child => {
            if (child.nodeType === 8) {
                child.remove();
            } else if (child.childNodes.length) {
                removeComments(child);
            }
        });
    })(element);

    // 除了允许的属性外，移除所有其他属性
    const keepAttributes = ['class', 'id', 'name', 'style', 'colspan', 'rowspan', 'align', 'valign', 'width', 'height'];
    function dfsRemoveAttributes(node) {
        if (node.nodeType === 1) {
            Array.from(node.attributes).forEach(attr => {
                if (!keepAttributes.includes(attr.name.toLowerCase())) {
                    node.removeAttribute(attr.name);
                }
            });
        }
        Array.from(node.childNodes).forEach(child => dfsRemoveAttributes(child));
    }
    dfsRemoveAttributes(element);

    // 压缩HTML内容
    const target = element.outerHTML;
    return target
        .replace(/>\s+</g, '><')
        .replace(/[\r\n]+/g, '')
        .replace(/\s{2,}/g, ' ')
        .trim();
}

/**
 * 课表HTML提取实现 - 使用启发式搜索从教务系统页面中提取课表部分
 */
function getSchedule(doc = document) {
    // 课表相关的关键词权重配置
    const KEYWORDS = {
        // 高权重 - 课表核心词汇
        high: ['课表', '课程表', '星期', '周次', '节次', '上课', '课程', 'schedule', 'course', 'timetable', 'kcb', 'kebiao'],
        // 中权重 - 时间相关
        medium: ['周一', '周二', '周三', '周四', '周五', '周六', '周日',
            '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日',
            'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
            '第一节', '第二节', '第三节', '第四节', '第五节',
            '1-2', '3-4', '5-6', '7-8', '9-10', '11-12',
            '上午', '下午', '晚上', '早上', '节次'],
        // 低权重 - 课程信息相关
        low: ['教室', '教师', '老师', '学分', '学时', '地点', '必修', '选修', '限选', '任选',
            '实验', '理论', '实践', '周', '节', '教学楼', '实验室', 'campus', 'room', 'teacher', 'week']
    };

    // 课表容器的常见CSS类名和ID模式
    const CONTAINER_PATTERNS = {
        classNames: [
            /course/i, /schedule/i, /timetable/i, /kebiao/i, /kecheng/i,
            /time-table/i, /class-table/i, /grid/i, /calendar/i, /kcb/i
        ],
        ids: [
            /course/i, /schedule/i, /timetable/i, /kebiao/i, /kecheng/i, /kcb/i
        ]
    };

    // 表格结构特征检测
    const TABLE_STRUCTURE = {
        minRows: 5,      // 课表至少有5行（表头+4个时间段）
        minCols: 5,      // 课表至少有5列（周一到周五）
        maxCols: 15      // 课表最多15列
    };

    /**
     * 计算元素的课表相关性得分
     */
    function calculateScore(element) {
        let score = 0;
        const text = element.innerText || element.textContent || '';
        const className = element.className || '';
        const id = element.id || '';

        // 1. 关键词匹配得分
        KEYWORDS.high.forEach(keyword => {
            const regex = new RegExp(keyword, 'gi');
            const matches = text.match(regex);
            if (matches) score += matches.length * 10;
        });

        KEYWORDS.medium.forEach(keyword => {
            const regex = new RegExp(keyword, 'gi');
            const matches = text.match(regex);
            if (matches) score += matches.length * 5;
        });

        KEYWORDS.low.forEach(keyword => {
            const regex = new RegExp(keyword, 'gi');
            const matches = text.match(regex);
            if (matches) score += matches.length * 2;
        });

        // 2.  容器模式匹配得分
        CONTAINER_PATTERNS.classNames.forEach(pattern => {
            if (pattern.test(className)) score += 20;
        });

        CONTAINER_PATTERNS.ids.forEach(pattern => {
            if (pattern.test(id)) score += 25;
        });

        // 3. 表格结构得分
        const tables = element.getElementsByTagName('table');
        for (let table of tables) {
            const tableScore = evaluateTableStructure(table);
            score += tableScore;
        }

        // 4. 星期几完整性检测（课表通常包含多个星期）
        const weekdayCount = countWeekdays(text);
        if (weekdayCount >= 5) score += 30;
        else if (weekdayCount >= 3) score += 15;

        // 5. 节次完整性检测
        const periodCount = countPeriods(text);
        if (periodCount >= 4) score += 25;
        else if (periodCount >= 2) score += 10;

        // 6. 惩罚过大或过小的元素
        const textLength = text.length;
        if (textLength < 50) score -= 20;  // 内容太少
        if (textLength > 20000) score -= 30; // 内容太多，可能包含了太多无关内容

        // 7. 优先选择更精确的容器（避免选择body等大容器）
        const tagName = element.tagName.toLowerCase();
        if (['body', 'html'].includes(tagName)) score -= 100;
        if (['div', 'table', 'section', 'article'].includes(tagName)) score += 10;

        return score;
    }

    /**
     * 评估表格结构是否符合课表特征
     */
    function evaluateTableStructure(table) {
        let score = 0;
        const rows = table.rows;

        if (!rows || rows.length < TABLE_STRUCTURE.minRows) return 0;

        // 检查列数
        const firstRow = rows[0];
        const colCount = firstRow ? firstRow.cells.length : 0;

        if (colCount >= TABLE_STRUCTURE.minCols && colCount <= TABLE_STRUCTURE.maxCols) {
            score += 30;
        }

        // 检查表头是否包含星期
        const headerText = firstRow ? (firstRow.innerText || '') : '';
        if (/星期|周[一二三四五六日]|Monday|Tuesday|Wednesday/i.test(headerText)) {
            score += 40;
        }

        // 检查是否有多行数据
        if (rows.length >= TABLE_STRUCTURE.minRows) {
            score += 20;
        }

        // 检查单元格中是否有课程信息特征（教师、教室、周次等）
        let courseInfoCount = 0;
        for (let i = 1; i < Math.min(rows.length, 5); i++) {
            const rowText = rows[i].innerText || '';
            if (/教师|老师|@|教室|周|节/.test(rowText)) {
                courseInfoCount++;
            }
        }
        if (courseInfoCount >= 2) score += 25;

        return score;
    }

    /**
     * 统计文本中出现的星期几数量
     */
    function countWeekdays(text) {
        const patterns = [
            /星期[一二三四五六日天]/g,
            /周[一二三四五六日天]/g,
            /(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)/gi
        ];

        const found = new Set();
        patterns.forEach(pattern => {
            const matches = text.match(pattern);
            if (matches) {
                matches.forEach(m => found.add(m.toLowerCase()));
            }
        });

        return found.size;
    }

    /**
     * 统计文本中出现的节次数量
     */
    function countPeriods(text) {
        const patterns = [
            /第[一二三四五六七八九十]+节/g,
            /[1-9]-[0-9]{1,2}/g,  // 如 1-2, 3-4
            /[一二三四五六七八九十]+[、,，][一二三四五六七八九十]+小节/g
        ];

        const found = new Set();
        patterns.forEach(pattern => {
            const matches = text.match(pattern);
            if (matches) {
                matches.forEach(m => found.add(m));
            }
        });

        return Math.min(found.size, 12); // 最多12节
    }

    /**
     * 递归搜索文档中的候选课表容器
     * @param candidates 存放候选元素的数组
     * @param doc 当前文档对象
     * @param sourcePrefix 来源标识前缀
     */
    function searchInDocument(candidates, doc, sourcePrefix) {
        if (!doc) return;
        // 策略1：表格及其父容器
        const tables = doc.getElementsByTagName('table');
        for (let table of tables) {
            candidates.push({ element: table, source: sourcePrefix + '-table' });
            let parent = table.parentElement;
            for (let i = 0; i < 3 && parent; i++) {
                candidates.push({ element: parent, source: sourcePrefix + '-table-parent' });
                parent = parent.parentElement;
            }
        }

        // 策略2：通过类名和ID模式查找
        const allElements = doc.querySelectorAll('div, section, article, main');
        for (let elem of allElements) {
            const className = elem.className || '';
            const id = elem.id || '';
            const matchesClass = CONTAINER_PATTERNS.classNames.some(p => p.test(className));
            const matchesId = CONTAINER_PATTERNS.ids.some(p => p.test(id));
            if (matchesClass || matchesId) {
                candidates.push({ element: elem, source: sourcePrefix + '-pattern-match' });
            }
        }

        // 策略3：包含大量课表关键词的容器
        for (let elem of allElements) {
            const text = elem.innerText || '';
            if (countWeekdays(text) >= 5 && text.length < 30000) {
                candidates.push({ element: elem, source: sourcePrefix + '-keyword-rich' });
            }
        }

        // 递归查找 iframe 和 frame 中的内容
        const frames = doc.querySelectorAll('iframe, frame');
        for (let frame of frames) {
            try {
                const frameDoc = frame.contentDocument || (frame.contentWindow ? frame.contentWindow.document : null);
                if (frameDoc) {
                    searchInDocument(candidates, frameDoc, sourcePrefix + '-' + frame.tagName.toLowerCase());
                }
            } catch (e) {
                // 忽略跨域错误或访问限制
            }
        }
    }

    /**
     * 查找最佳课表容器
     */
    function findBestScheduleContainer() {
        const candidates = [];
        // 在主文档中搜索
        searchInDocument(candidates, doc, 'main');

        // 去重
        const uniqueCandidates = [];
        const seen = new Set();
        for (let c of candidates) {
            if (!seen.has(c.element)) {
                seen.add(c.element);
                uniqueCandidates.push(c);
            }
        }

        // 计算得分并排序
        const scored = uniqueCandidates.map(c => ({
            ...c,
            score: calculateScore(c.element)
        }));
        scored.sort((a, b) => b.score - a.score);
//        console.log('候选课表容器评分:', scored.map(s => ({
//            source: s.source,
//            score: s.score,
//            tagName: s.element.tagName,
//            className: s.element.className,
//            id: s.element.id
//        })));

        // 返回得分最高的元素
        if (scored.length > 0 && scored[0].score > 50) {
            return scored[0];
        }

        return null;
    }

    const result = {
        success: false,
        html: '',
    };

    try {
        const best = findBestScheduleContainer();
        if (best) {
            result.success = true;
            result.html = compress(best.element.cloneNode(true));
            result.debug = {
                source: best.source,
                score: best.score,
                tagName: best.element.tagName,
                className: best.element.className,
                id: best.element.id,
                originalLength: best.element.outerHTML.length,
                cleanedLength: result.html.length
            };
        } else {
            // 降级方案：返回整个body
            result.success = false;
            result.html = compress(doc.body.cloneNode(true));
            result.debug = {
                message: '未找到合适的课程表容器，返回已清理的主体内容',
                bodyLength: doc.body.outerHTML.length,
                cleanedLength: result.html.length
            };
        }
    } catch (error) {
        result.success = false;
        result.error = error.message;
        console.error('提取课程时出错: ', error);
    }

    return result;
}