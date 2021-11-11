enum BlockType
    Empty
    Exist

struct Note
    _type: BlockType

struct NoteLayer
    timeCode: float
    notes: Note[4]

struct Level
    sound : string
    velocity: float

var level1_layers <- [{ auto
    [[NoteLayer timeCode=1f, notes=[[ auto
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Exist]];
            [[Note _type = BlockType Exist]];
            [[Note _type = BlockType Empty]]
        ]]
    ]];
    [[NoteLayer timeCode=2.25f, notes=[[ auto
            [[Note _type = BlockType Exist]];
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Exist]]
        ]]
    ]];
    [[NoteLayer timeCode=2.50f, notes=[[ auto
            [[Note _type = BlockType Exist]];
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Exist]]
        ]]
    ]];
    [[NoteLayer timeCode=2.75f, notes=[[ auto
            [[Note _type = BlockType Exist]];
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Exist]]
        ]]
    ]]
}]

var level1 <- [[Level sound="sound/promo.mp3", velocity=300f]]
