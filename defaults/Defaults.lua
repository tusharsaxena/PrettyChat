local _, NS = ...

-- defaults/Defaults.lua — NS.Defaults, the per-category reference data: every GLOBALNAME
-- PrettyChat overrides, with its row label and the PrettyChat format it defaults to.
--
-- `order` is the entry's place in its category's list (the settings list, `/pc list`, the
-- `/pc test` report, the schema walk), read by NS.SortedStringNames in modules/Override.lua.
-- Display data only: it is never a SavedVariables key. The curated rule (item 020, PRC-L01)
-- is kind first, then Self before Other, then single before Multiple, odd ones last; an
-- entry with no `order` sorts by GLOBALNAME after the ranked ones, so a new string can never
-- vanish from the list.

NS.Defaults = {
    Loot = {
        enabled = true,
        strings = {
            BATTLE_PET_LOOT_RECEIVED = {
                order = 13,
                label = "Battle Pet Loot",
                default = "|cffff0000Loot|cffffffff | |cff93c47dYou|cffffffff ",
            },
            LOOT_CURRENCY_REFUND = {
                order = 17,
                label = "Currency Refund",
                default = "|cffff0000Loot|cffffffff | |cffe06666Refund|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            LOOT_DISENCHANT_CREDIT = {
                order = 14,
                label = "Disenchant Credit",
                default = "|cffff0000Loot|cffffffff | |cff8e7cc3Disenchant|cffffffff | |cfff6b26b%s|cffffffff ",
            },
            LOOT_ITEM = {
                order = 3,
                label = "Item Looted (Other)",
                default = "|cffff0000Loot|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %s|cffffffff",
            },
            LOOT_ITEM_BONUS_ROLL = {
                order = 11,
                label = "Bonus Roll (Other)",
                default = "|cffff0000Loot|cffffffff | |cff76a5afBonus|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %s|cffffffff",
            },
            LOOT_ITEM_BONUS_ROLL_MULTIPLE = {
                order = 12,
                label = "Bonus Roll Multiple (Other)",
                default = "|cffff0000Loot|cffffffff | |cff76a5afBonus|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            LOOT_ITEM_BONUS_ROLL_SELF = {
                order = 9,
                label = "Bonus Roll (Self)",
                default = "|cffff0000Loot|cffffffff | |cff76a5afBonus|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s|cffffffff",
            },
            LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE = {
                order = 10,
                label = "Bonus Roll Multiple (Self)",
                default = "|cffff0000Loot|cffffffff | |cff76a5afBonus|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            LOOT_ITEM_MULTIPLE = {
                order = 4,
                label = "Item Looted Multiple (Other)",
                default = "|cffff0000Loot|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            LOOT_ITEM_PUSHED = {
                order = 7,
                label = "Item Pushed (Other)",
                default = "|cffff0000Loot|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %s|cffffffff",
            },
            LOOT_ITEM_PUSHED_MULTIPLE = {
                order = 8,
                label = "Item Pushed Multiple (Other)",
                default = "|cffff0000Loot|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            LOOT_ITEM_PUSHED_SELF = {
                order = 5,
                label = "Item Pushed (Self)",
                default = "|cffff0000Loot|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s|cffffffff",
            },
            LOOT_ITEM_PUSHED_SELF_MULTIPLE = {
                order = 6,
                label = "Item Pushed Multiple (Self)",
                default = "|cffff0000Loot|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            LOOT_ITEM_REFUND = {
                order = 15,
                label = "Item Refund",
                default = "|cffff0000Loot|cffffffff | |cffe06666Refund|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s|cffffffff",
            },
            LOOT_ITEM_REFUND_MULTIPLE = {
                order = 16,
                label = "Item Refund (Multiple)",
                default = "|cffff0000Loot|cffffffff | |cffe06666Refund|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            LOOT_ITEM_SELF = {
                order = 1,
                label = "Item Looted (Self)",
                default = "|cffff0000Loot|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s|cffffffff",
            },
            LOOT_ITEM_SELF_MULTIPLE = {
                order = 2,
                label = "Item Looted Multiple (Self)",
                default = "|cffff0000Loot|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
        },
    },
    Currency = {
        enabled = true,
        strings = {
            CURRENCY_GAINED = {
                order = 1,
                label = "Currency Gained",
                default = "|cffff9900Currency|cffffffff | |cffffffff+ %s|cffffffff",
            },
            CURRENCY_GAINED_MULTIPLE = {
                order = 2,
                label = "Currency Gained Multiple",
                default = "|cffff9900Currency|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            CURRENCY_GAINED_MULTIPLE_BONUS = {
                order = 3,
                label = "Currency Gained Multiple (Bonus)",
                default = "|cffff9900Currency|cffffffff | |cff76a5afBonus Objective|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            CURRENCY_LOST_FROM_DEATH = {
                order = 4,
                label = "Currency Lost (Death)",
                default = "|cffff9900Currency|cffffffff | |cffe06666Lost|cffffffff | |cffffffff- %s x%d|cffffffff",
            },
        },
    },
    Money = {
        enabled = true,
        strings = {
            LOOT_MONEY = {
                order = 2,
                label = "Money Looted (Other)",
                default = "|cffffff00Money|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %s|cffffffff",
            },
            LOOT_MONEY_REFUND = {
                order = 6,
                label = "Money Refund",
                default = "|cffffff00Money|cffffffff | |cffe06666Refund|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s|cffffffff",
            },
            LOOT_MONEY_SPLIT = {
                order = 5,
                label = "Money Split",
                default = "|cffffff00Money|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s|cffffffff",
            },
            YOU_LOOT_MONEY = {
                order = 1,
                label = "Money Looted (Self)",
                default = "|cffffff00Money|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s|cffffffff",
            },
            YOU_LOOT_MONEY_GUILD = {
                order = 4,
                label = "Money Looted (Guild Bank)",
                default = "|cffffff00Money|cffffffff | |cff93c47dGuild Bank|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s (+ %s guild bank)|cffffffff",
            },
            YOU_LOOT_MONEY_MOD = {
                order = 3,
                label = "Money Looted (Modifier)",
                default = "|cffffff00Money|cffffffff | |cff93c47dYou|cffffffff | |cffffffff%s (+ %s)|cffffffff",
            },
            GENERIC_MONEY_GAINED_RECEIPT = {
                order = 8,
                label = "Money Gained (Generic)",
                default = "|cffffff00Money|cffffffff | |cffccccccGeneric|cffffffff | |cffffffff+ %s|cffffffff",
            },
            ERR_QUEST_REWARD_MONEY_S = {
                order = 7,
                label = "Money Gained (Quest Reward)",
                default = "|cffffff00Money|cffffffff | |cffccccccQuest Reward|cffffffff | |cffffffff+ %s|cffffffff",
            },
        },
    },
    Reputation = {
        enabled = true,
        strings = {
            FACTION_STANDING_CHANGED = {
                order = 12,
                label = "Standing Changed",
                default = "|cff00ff00Rep|cffffffff | |cff76a5afStanding|cffffffff | |cffffffff%s - %s|cffffffff",
            },
            FACTION_STANDING_CHANGED_GUILD = {
                order = 13,
                label = "Standing Changed (Guild)",
                default = "|cff00ff00Rep|cffffffff | |cff76a5afStanding|cffffffff | |cffffffff%s - Guild|cffffffff",
            },
            FACTION_STANDING_CHANGED_GUILDNAME = {
                order = 14,
                label = "Standing Changed (Guild Name)",
                default = "|cff00ff00Rep|cffffffff | |cff76a5afStanding|cffffffff | |cffffffff%s - %s|cffffffff",
            },
            FACTION_STANDING_DECREASED = {
                order = 10,
                label = "Standing Decreased",
                default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff | |cffffffff- %d|cffffffff",
            },
            FACTION_STANDING_DECREASED_GENERIC = {
                order = 11,
                label = "Standing Decreased (Generic)",
                default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff ",
            },
            FACTION_STANDING_INCREASED = {
                order = 1,
                label = "Standing Increased",
                default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff | |cffffffff+ %d|cffffffff",
            },
            FACTION_STANDING_INCREASED_ACH_BONUS = {
                order = 3,
                label = "Standing Increased (Achievement Bonus)",
                default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff | |cffffffff+ %d (+ %.1f bonus)|cffffffff",
            },
            FACTION_STANDING_INCREASED_ACH_PART = {
                order = 4,
                label = "Standing Increased (Achievement Part)",
                default = "|cff00ff00Rep|cffffffff | |cffcccccc:|cffffffff | |cffffffff(+ %.1f bonus)|cffffffff",
            },
            FACTION_STANDING_INCREASED_BONUS = {
                order = 8,
                label = "Standing Increased (RAF Bonus)",
                default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff | |cffffffff+ %d (+ %.1f Recruit A Friend bonus)|cffffffff",
            },
            FACTION_STANDING_INCREASED_DOUBLE_BONUS = {
                order = 5,
                label = "Standing Increased (Double Bonus)",
                default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff | |cffffffff+ %d (+ %.1f Recruit A Friend bonus) (+ %.1f bonus)|cffffffff",
            },
            FACTION_STANDING_INCREASED_GENERIC = {
                order = 2,
                label = "Standing Increased (Generic)",
                default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff ",
            },
            FACTION_STANDING_INCREASED_GUARDIAN = {
                order = 6,
                label = "Standing Increased (Guardian)",
                default = "|cff00ff00Rep|cffffffff | |cff76a5af%s|cffffffff | |cffccccccGuardian|cffffffff | |cffffffff+ %d|cffffffff",
            },
            FACTION_STANDING_INCREASED_REFER_PART = {
                order = 9,
                label = "Standing Increased (RAF Part)",
                default = "|cff00ff00Rep|cffffffff | |cffccccccRAF|cffffffff | |cffffffff(+ %.1f Recruit A Friend bonus)|cffffffff",
            },
            FACTION_STANDING_INCREASED_REST_PART = {
                order = 7,
                label = "Standing Increased (Rested Part)",
                default = "|cff00ff00Rep|cffffffff | |cffccccccRested|cffffffff | |cffffffff(+ %.1f Rested bonus)|cffffffff",
            },
        },
    },
    Experience = {
        enabled = true,
        strings = {
            COMBATLOG_XPGAIN_EXHAUSTION1 = {
                order = 1,
                label = "XP Gain (Rested)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s bonus)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION1_GROUP = {
                order = 2,
                label = "XP Gain (Rested, Group)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s bonus, + %d group bonus)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION1_RAID = {
                order = 3,
                label = "XP Gain (Rested, Raid)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s bonus, - %d raid penalty)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION2 = {
                order = 4,
                label = "XP Gain (Normal)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s bonus)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION2_GROUP = {
                order = 5,
                label = "XP Gain (Normal, Group)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s bonus, + %d group bonus)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION2_RAID = {
                order = 6,
                label = "XP Gain (Normal, Raid)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s bonus, - %d raid penalty)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION4 = {
                order = 7,
                label = "XP Gain (Tired)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s penalty)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION4_GROUP = {
                order = 8,
                label = "XP Gain (Tired, Group)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s penalty, + %d group bonus)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION4_RAID = {
                order = 9,
                label = "XP Gain (Tired, Raid)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s penalty, - %d raid penalty)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION5 = {
                order = 10,
                label = "XP Gain (Exhausted)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s penalty)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION5_GROUP = {
                order = 11,
                label = "XP Gain (Exhausted, Group)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s penalty, + %d group bonus)|cffffffff",
            },
            COMBATLOG_XPGAIN_EXHAUSTION5_RAID = {
                order = 12,
                label = "XP Gain (Exhausted, Raid)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s exp %s penalty, - %d raid penalty)|cffffffff",
            },
            COMBATLOG_XPGAIN_FIRSTPERSON = {
                order = 13,
                label = "XP Gain (Kill, No Bonus)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d|cffffffff",
            },
            COMBATLOG_XPGAIN_FIRSTPERSON_GROUP = {
                order = 14,
                label = "XP Gain (Kill, No Bonus, Group)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (+ %d group bonus)|cffffffff",
            },
            COMBATLOG_XPGAIN_FIRSTPERSON_RAID = {
                order = 15,
                label = "XP Gain (Kill, No Bonus, Raid)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (- %d raid penalty)|cffffffff",
            },
            COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED = {
                order = 16,
                label = "XP Gain (No Source)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26bUnknown|cffffffff | |cffffffff+ %d|cffffffff",
            },
            COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GROUP = {
                order = 17,
                label = "XP Gain (No Source, Group)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26bUnknown|cffffffff | |cffffffff+ %d (+ %d group bonus)|cffffffff",
            },
            COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_RAID = {
                order = 18,
                label = "XP Gain (No Source, Raid)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26bUnknown|cffffffff | |cffffffff+ %d (- %d raid penalty)|cffffffff",
            },
            COMBATLOG_XPGAIN_QUEST = {
                order = 19,
                label = "XP Gain (Quest)",
                default = "|cff00ffffXP|cffffffff | |cfff6b26bUnknown|cffffffff | |cffffffff+ %d (%s exp %s bonus)|cffffffff",
            },
            COMBATLOG_XPLOSS_FIRSTPERSON_UNNAMED = {
                order = 20,
                label = "XP Loss",
                default = "|cff00ffffXP|cffffffff | |cfff6b26bUnknown|cffffffff | |cffffffff- %d|cffffffff",
            },
        },
    },
    Honor = {
        enabled = true,
        strings = {
            COMBATLOG_DISHONORGAIN = {
                order = 6,
                label = "Dishonorable Kill",
                default = "|cff4a86e8Honor|cffffffff | |cffe06666:|cffffffff | |cffffffffDishonorable Kill|cffffffff",
            },
            COMBATLOG_HONORAWARD = {
                order = 5,
                label = "Honor Award",
                default = "|cff4a86e8Honor|cffffffff | |cffffffff+ %d|cffffffff",
            },
            COMBATLOG_HONORGAIN = {
                order = 1,
                label = "Honor Gain",
                default = "|cff4a86e8Honor|cffffffff | |cfff6b26b%s (%s)|cffffffff | |cffffffff+ %d|cffffffff",
            },
            COMBATLOG_HONORGAIN_EXHAUSTION1 = {
                order = 2,
                label = "Honor Gain (Rested)",
                default = "|cff4a86e8Honor|cffffffff | |cfff6b26b%s (%s)|cffffffff | |cffffffff+ %d (%s %s bonus)|cffffffff",
            },
            COMBATLOG_HONORGAIN_NO_RANK = {
                order = 3,
                label = "Honor Gain (No Rank)",
                default = "|cff4a86e8Honor|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d|cffffffff",
            },
            COMBATLOG_HONORGAIN_NO_RANK_EXHAUSTION1 = {
                order = 4,
                label = "Honor Gain (No Rank, Rested)",
                default = "|cff4a86e8Honor|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %d (%s %s bonus)|cffffffff",
            },
        },
    },
    Tradeskill = {
        enabled = true,
        strings = {
            CREATED_ITEM = {
                order = 3,
                label = "Created Item (Other)",
                default = "|cffff00ffTradeskill|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %s|cffffffff",
            },
            CREATED_ITEM_MULTIPLE = {
                order = 4,
                label = "Created Item Multiple (Other)",
                default = "|cffff00ffTradeskill|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            LOOT_ITEM_CREATED_SELF = {
                order = 1,
                label = "Created Item (Self)",
                default = "|cffff00ffTradeskill|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s|cffffffff",
            },
            LOOT_ITEM_CREATED_SELF_MULTIPLE = {
                order = 2,
                label = "Created Item Multiple (Self)",
                default = "|cffff00ffTradeskill|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s x%d|cffffffff",
            },
            TRADESKILL_LOG_FIRSTPERSON = {
                order = 5,
                label = "Tradeskill Log (Self)",
                default = "|cffff00ffTradeskill|cffffffff | |cff93c47dYou|cffffffff | |cffffffff+ %s|cffffffff",
            },
            TRADESKILL_LOG_THIRDPERSON = {
                order = 6,
                label = "Tradeskill Log (Other)",
                default = "|cffff00ffTradeskill|cffffffff | |cfff6b26b%s|cffffffff | |cffffffff+ %s|cffffffff",
            },
            OPEN_LOCK_OTHER = {
                order = 8,
                label = "Open Lock (Other)",
                default = "|cffff00ff%s|cffffffff | |cfff6b26b%s|cffffffff ",
            },
            OPEN_LOCK_SELF = {
                order = 7,
                label = "Open Lock (Self)",
                default = "|cffff00ff%s|cffffffff | |cff93c47dYou|cffffffff ",
            },
        },
    },
    Misc = {
        enabled = true,
        strings = {
            ERR_QUEST_REWARD_EXP_I = {
                order = 1,
                label = "Quest Reward XP",
                default = "|cffffffffMisc|cffffffff | |cffccccccExp|cffffffff | |cffffffff+ %d|cffffffff",
            },
            ERR_ZONE_EXPLORED_XP = {
                order = 2,
                label = "Zone Explored XP",
                default = "|cffffffffDiscovery XP|cffffffff | |cffcccccc%s|cffffffff | |cffffffff+ %d|cffffffff",
            },
        },
    },
}
