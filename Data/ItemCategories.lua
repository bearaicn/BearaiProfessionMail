local _, ns = ...
-- 游戏物品类别与专业用途是两个维度；普通物品分类不推断专业。
-- 使用客户端返回的稳定 classID/subclassID；未知子类保留到大类兜底。
ns.ItemCategories = {
    {id="cloth",name="布料",classID=7,subclassID=5},
    {id="leather",name="皮革",classID=7,subclassID=6},
    {id="metal",name="金属矿石",classID=7,subclassID=7},
    {id="herb",name="草药",classID=7,subclassID=9},
    {id="cooking",name="烹饪原料",classID=7,subclassID=8},
    {id="enchanting",name="附魔原料",classID=7,subclassID=12},
    {id="parts",name="工程部件",classID=7,subclassID=1},
    {id="devices",name="工程设备",classID=7,subclassID=3},
    {id="explosives",name="爆炸物",classID=7,subclassID=2},
    {id="element",name="元素原料",classID=7,subclassID=10},
    {id="jewel",name="珠宝原料",classID=7,subclassID=4},
    {id="gems",name="宝石",classID=3},
    {id="consumable",name="消耗品",classID=0},
    {id="equipment",name="装备",classes={[2]=true,[4]=true}},
    {id="recipe",name="配方书",classID=9},
    {id="tradegoods",name="其他材料",classes={[5]=true,[7]=true}},
}
