local base = game:GetService("CoreGui").RobloxGui.SettingsClippingShield.SettingsShield.MenuContainer
local page = base.Page.PageViewClipper.PageView.PageViewInnerFrame.Page

if getgenv().assets and getgenv().assets.bgswnmo then
    base.Image = getgenv().assets.bgswnmo
end
base.ImageTransparency = 0.45

page["Voice ChatFrame"].Selector.Selection2.Text = "Люблю пиздачить"
page["Voice ChatFrame"].Selector.Selection1.Text = "Не люблю пиздеть"
page["Maximum Frame RateFrame"]["Maximum Frame RateRowLabelAndDescriptionFrame"]["Maximum Frame RateLabel"].Text = "MAXимальный FPS Rate"

local toHide = {
    page.VRFrame,
    page["UI navigation toggleFrame"],
    page["Performance StatsFrame"],
    page["Give Translation FeedbackFrame"],
    page["My BadgesFrame"],
}
for _, v in ipairs(toHide) do
    v.Visible = false
end

local hubBar = base.Page.HubBar.TabHeaderContainer.HubBarContainer
hubBar.HelpTab.Visible = false
hubBar.ReportAbuseTab.Visible = false

base.Page.MenuListLayout.SortOrder = Enum.SortOrder.Custom

local padding = base.Page.UIPadding
padding.PaddingBottom = UDim.new(0, 25)
padding.PaddingLeft = UDim.new(0, 25)
padding.PaddingRight = UDim.new(0, 25)
padding.PaddingTop = UDim.new(0, 25)

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = base.Page.PageViewClipper.PageView