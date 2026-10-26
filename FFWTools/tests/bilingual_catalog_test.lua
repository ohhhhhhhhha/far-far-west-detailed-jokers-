-- Offline catalog checks; loads no engine code and writes no game state.
local root = (arg[0]:gsub('\\', '/'):match('^(.*)/tests/')) or 'FFWTools'
local english = dofile(root .. '/src/FFWJokerInfo/Scripts/English.lua')
local cards = dofile(root .. '/src/FFWJokerInfo/Scripts/CardText.lua')
local translations, cardCount, described, ids = 0, 0, 0, {}
for zh, en in pairs(english) do
    assert(type(zh) == 'string' and zh ~= '', 'Invalid catalog key')
    assert(type(en) == 'string' and en ~= '', 'Invalid English translation')
    assert(utf8.len(zh) and utf8.len(en), 'Invalid UTF-8 in catalog')
    translations = translations + 1
end
for id, text in pairs(cards) do
    assert(type(id) == 'string' and id:match('^joker'), 'Invalid card ID')
    assert(not ids[id:lower()], 'Duplicate card ID ignoring case: ' .. id)
    ids[id:lower()] = true
    for _, field in ipairs({'zhName', 'enName', 'zhDescription', 'enDescription'}) do
        assert(type(text[field]) == 'string', id .. ': missing ' .. field)
        assert(utf8.len(text[field]), id .. ': invalid UTF-8 in ' .. field)
    end
    assert(text.zhName ~= '' and text.enName ~= '', id .. ': blank name')
    assert((text.zhDescription == '') == (text.enDescription == ''), id .. ': missing description in one language')
    if text.enDescription ~= '' then described = described + 1 end
    cardCount = cardCount + 1
end
assert(english['组合换弹速率'] == 'Combined reload rate')
assert(english['已装备'] == 'Equipped ' and english['系法术数'] == ' spells', 'Lost dynamic-fragment spacing')
assert(string.format(english['%.1f%%（%s / %s）'], 50, 1, 2) == '50.0% (1 / 2)', 'Invalid numeric format')
assert(cards.jokerBloodLust.enName == 'BLOODLUST', 'Stock name must use official FText')
assert(cards.jokerUpgradeDamage.enDescription == '', 'Blank stock upgrade description must remain blank')
print(('PASS: Lua loaded %d translations and %d bilingual cards (%d descriptions; %d intentionally blank upgrade descriptions).'):format(translations, cardCount, described, cardCount-described))
