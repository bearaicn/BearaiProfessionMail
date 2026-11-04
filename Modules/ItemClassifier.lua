local _, ns = ...
local I = {}
ns.ItemClassifier = I
function I.Classify(row)
    if row.classID == nil then return "pending","待识别" end
    for _, category in ipairs(ns.ItemCategories) do
        if (category.classID==row.classID or (category.classes and category.classes[row.classID]))
            and (category.subclassID==nil or category.subclassID==row.subclassID) then
            return category.id,category.name
        end
    end
    return "other","其他物品"
end
function I.Match(row, category)
    return not category or category=="all" or I.Classify(row)==category
end
function I.Options()
    local result = {{value="all",text="全部类别"}}
    for _, category in ipairs(ns.ItemCategories) do result[#result+1]={value=category.id,text=category.name} end
    result[#result+1]={value="other",text="其他物品"}
    result[#result+1]={value="pending",text="待识别"}
    return result
end
function I.Describe(row)
    local categoryID,categoryName = I.Classify(row)
    local source=ns.MaterialMatcher.Source(row.itemID)
    local state = source=="new" and "专业用途未收录" or
        (source=="user" and "用户规则" or "助手规则")
    if source=="user" and not next(ns.MaterialMatcher.Rule(row.itemID)) then state="用户已排除专业匹配" end
    return categoryID,categoryName,state
end
