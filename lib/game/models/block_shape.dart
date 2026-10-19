import 'package:flutter/material.dart';
import '../../core/theme/game_colors.dart';

class BlockShape {
  final String id;
  final List<List<bool>> matrix;
  final Color color;

  const BlockShape({
    required this.id,
    required this.matrix,
    required this.color,
  });

  int get rows => matrix.length;
  int get cols => matrix.isEmpty ? 0 : matrix[0].length;

  int get blockCount {
    int count = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (matrix[r][c]) count++;
      }
    }
    return count;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BlockShape && other.id == id);

  @override
  int get hashCode => id.hashCode;

  // Predefined catalog of shapes
  // Predefined catalog of shapes (1, 2, 3, 4, 6, 8, 9 cells only)
  static List<BlockShape> get catalog => [
        // 1-CELL (1)
        BlockShape(
          id: 'single_1x1',
          matrix: [
            [true]
          ],
          color: GameColors.getBlockColor(0),
        ),
        
        // 2-CELLS (2)
        BlockShape(
          id: 'horiz_2',
          matrix: [[true, true]],
          color: GameColors.getBlockColor(1),
        ),
        BlockShape(
          id: 'vert_2',
          matrix: [[true], [true]],
          color: GameColors.getBlockColor(1),
        ),
        
        // 3-CELLS (3)
        BlockShape(
          id: 'horiz_3',
          matrix: [[true, true, true]],
          color: GameColors.getBlockColor(2),
        ),
        BlockShape(
          id: 'vert_3',
          matrix: [[true], [true], [true]],
          color: GameColors.getBlockColor(2),
        ),
        BlockShape(
          id: 'l_small_tl',
          matrix: [[true, true], [true, false]],
          color: GameColors.getBlockColor(7),
        ),
        BlockShape(
          id: 'l_small_tr',
          matrix: [[true, true], [false, true]],
          color: GameColors.getBlockColor(7),
        ),
        BlockShape(
          id: 'l_small_bl',
          matrix: [[true, false], [true, true]],
          color: GameColors.getBlockColor(7),
        ),
        BlockShape(
          id: 'l_small_br',
          matrix: [[false, true], [true, true]],
          color: GameColors.getBlockColor(7),
        ),

        // 4-CELLS (4)
        BlockShape(
          id: 'horiz_4',
          matrix: [[true, true, true, true]],
          color: GameColors.getBlockColor(3),
        ),
        BlockShape(
          id: 'vert_4',
          matrix: [[true], [true], [true], [true]],
          color: GameColors.getBlockColor(3),
        ),
        BlockShape(
          id: 'square_2x2',
          matrix: [[true, true], [true, true]],
          color: GameColors.getBlockColor(5),
        ),
        BlockShape(
          id: 't_up',
          matrix: [[true, true, true], [false, true, false]],
          color: GameColors.getBlockColor(4),
        ),
        BlockShape(
          id: 't_down',
          matrix: [[false, true, false], [true, true, true]],
          color: GameColors.getBlockColor(4),
        ),
        BlockShape(
          id: 't_left',
          matrix: [[false, true], [true, true], [false, true]],
          color: GameColors.getBlockColor(4),
        ),
        BlockShape(
          id: 't_right',
          matrix: [[true, false], [true, true], [true, false]],
          color: GameColors.getBlockColor(4),
        ),
        BlockShape(
          id: 'l_4_right',
          matrix: [[true, false], [true, false], [true, true]],
          color: GameColors.getBlockColor(7),
        ),
        BlockShape(
          id: 'l_4_left',
          matrix: [[false, true], [false, true], [true, true]],
          color: GameColors.getBlockColor(7),
        ),
        BlockShape(
          id: 'l_4_up',
          matrix: [[true, true, true], [true, false, false]],
          color: GameColors.getBlockColor(7),
        ),
        BlockShape(
          id: 'l_4_down',
          matrix: [[true, true, true], [false, false, true]],
          color: GameColors.getBlockColor(7),
        ),
        BlockShape(
          id: 's_shape_horiz',
          matrix: [[false, true, true], [true, true, false]],
          color: GameColors.getBlockColor(6),
        ),
        BlockShape(
          id: 'z_shape_horiz',
          matrix: [[true, true, false], [false, true, true]],
          color: GameColors.getBlockColor(6),
        ),
        BlockShape(
          id: 's_shape_vert',
          matrix: [[true, false], [true, true], [false, true]],
          color: GameColors.getBlockColor(6),
        ),
        BlockShape(
          id: 'z_shape_vert',
          matrix: [[false, true], [true, true], [true, false]],
          color: GameColors.getBlockColor(6),
        ),

        // 6-CELLS (6)
        BlockShape(
          id: 'rect_2x3',
          matrix: [[true, true, true], [true, true, true]],
          color: GameColors.getBlockColor(6),
        ),
        BlockShape(
          id: 'rect_3x2',
          matrix: [[true, true], [true, true], [true, true]],
          color: GameColors.getBlockColor(6),
        ),

        // 8-CELLS (8)
        BlockShape(
          id: 'rect_2x4',
          matrix: [[true, true, true, true], [true, true, true, true]],
          color: GameColors.getBlockColor(0),
        ),
        BlockShape(
          id: 'rect_4x2',
          matrix: [[true, true], [true, true], [true, true], [true, true]],
          color: GameColors.getBlockColor(0),
        ),

        // 9-CELLS (9)
        BlockShape(
          id: 'square_3x3',
          matrix: [
            [true, true, true],
            [true, true, true],
            [true, true, true]
          ],
          color: GameColors.getBlockColor(1),
        ),
      ];
}
