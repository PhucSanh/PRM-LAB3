import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Extended Habits Evaluation and Lotus Reward Unit Tests', () {
    test('Evaluation case 001: verifies streak of 1 days earns Bông Sen Xanh', () {
      final currentStreak = 1;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 10);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Xanh');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 002: verifies streak of 2 days earns Bông Sen Xanh', () {
      final currentStreak = 2;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 20);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Xanh');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 003: verifies streak of 3 days earns Bông Sen Xanh', () {
      final currentStreak = 3;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 30);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Xanh');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 004: verifies streak of 4 days earns Bông Sen Xanh', () {
      final currentStreak = 4;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 40);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Xanh');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 005: verifies streak of 5 days earns Bông Sen Xanh', () {
      final currentStreak = 5;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 50);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Xanh');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 006: verifies streak of 6 days earns Bông Sen Xanh', () {
      final currentStreak = 6;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 60);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Xanh');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 007: verifies streak of 7 days earns Bông Sen Vàng', () {
      final currentStreak = 7;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 70);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Vàng');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 008: verifies streak of 8 days earns Bông Sen Vàng', () {
      final currentStreak = 8;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 80);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Vàng');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 009: verifies streak of 9 days earns Bông Sen Vàng', () {
      final currentStreak = 9;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 90);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Vàng');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 010: verifies streak of 10 days earns Bông Sen Vàng', () {
      final currentStreak = 10;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 100);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Vàng');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 011: verifies streak of 11 days earns Bông Sen Vàng', () {
      final currentStreak = 11;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 110);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Vàng');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 012: verifies streak of 12 days earns Bông Sen Vàng', () {
      final currentStreak = 12;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 120);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Vàng');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 013: verifies streak of 13 days earns Bông Sen Vàng', () {
      final currentStreak = 13;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 130);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Bông Sen Vàng');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 014: verifies streak of 14 days earns Cây Tùng Bách', () {
      final currentStreak = 14;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 140);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 015: verifies streak of 15 days earns Cây Tùng Bách', () {
      final currentStreak = 15;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 150);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 016: verifies streak of 16 days earns Cây Tùng Bách', () {
      final currentStreak = 16;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 160);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 017: verifies streak of 17 days earns Cây Tùng Bách', () {
      final currentStreak = 17;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 170);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 018: verifies streak of 18 days earns Cây Tùng Bách', () {
      final currentStreak = 18;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 180);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 019: verifies streak of 19 days earns Cây Tùng Bách', () {
      final currentStreak = 19;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 190);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 020: verifies streak of 20 days earns Cây Tùng Bách', () {
      final currentStreak = 20;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 200);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 021: verifies streak of 21 days earns Cây Tùng Bách', () {
      final currentStreak = 21;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 210);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 022: verifies streak of 22 days earns Cây Tùng Bách', () {
      final currentStreak = 22;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 220);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 023: verifies streak of 23 days earns Cây Tùng Bách', () {
      final currentStreak = 23;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 230);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 024: verifies streak of 24 days earns Cây Tùng Bách', () {
      final currentStreak = 24;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 240);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 025: verifies streak of 25 days earns Cây Tùng Bách', () {
      final currentStreak = 25;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 250);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 026: verifies streak of 26 days earns Cây Tùng Bách', () {
      final currentStreak = 26;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 260);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 027: verifies streak of 27 days earns Cây Tùng Bách', () {
      final currentStreak = 27;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 270);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 028: verifies streak of 28 days earns Cây Tùng Bách', () {
      final currentStreak = 28;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 280);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 029: verifies streak of 29 days earns Cây Tùng Bách', () {
      final currentStreak = 29;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 290);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 030: verifies streak of 30 days earns Cây Tùng Bách', () {
      final currentStreak = 30;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 300);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 031: verifies streak of 31 days earns Cây Tùng Bách', () {
      final currentStreak = 31;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 310);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 032: verifies streak of 32 days earns Cây Tùng Bách', () {
      final currentStreak = 32;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 320);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 033: verifies streak of 33 days earns Cây Tùng Bách', () {
      final currentStreak = 33;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 330);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 034: verifies streak of 34 days earns Cây Tùng Bách', () {
      final currentStreak = 34;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 340);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 035: verifies streak of 35 days earns Cây Tùng Bách', () {
      final currentStreak = 35;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 350);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 036: verifies streak of 36 days earns Cây Tùng Bách', () {
      final currentStreak = 36;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 360);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 037: verifies streak of 37 days earns Cây Tùng Bách', () {
      final currentStreak = 37;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 370);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 038: verifies streak of 38 days earns Cây Tùng Bách', () {
      final currentStreak = 38;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 380);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 039: verifies streak of 39 days earns Cây Tùng Bách', () {
      final currentStreak = 39;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 390);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 040: verifies streak of 40 days earns Cây Tùng Bách', () {
      final currentStreak = 40;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 400);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 041: verifies streak of 41 days earns Cây Tùng Bách', () {
      final currentStreak = 41;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 410);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 042: verifies streak of 42 days earns Cây Tùng Bách', () {
      final currentStreak = 42;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 420);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 043: verifies streak of 43 days earns Cây Tùng Bách', () {
      final currentStreak = 43;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 430);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 044: verifies streak of 44 days earns Cây Tùng Bách', () {
      final currentStreak = 44;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 440);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 045: verifies streak of 45 days earns Cây Tùng Bách', () {
      final currentStreak = 45;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 450);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 046: verifies streak of 46 days earns Cây Tùng Bách', () {
      final currentStreak = 46;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 460);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 047: verifies streak of 47 days earns Cây Tùng Bách', () {
      final currentStreak = 47;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 470);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 048: verifies streak of 48 days earns Cây Tùng Bách', () {
      final currentStreak = 48;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 480);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 049: verifies streak of 49 days earns Cây Tùng Bách', () {
      final currentStreak = 49;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 490);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 050: verifies streak of 50 days earns Cây Tùng Bách', () {
      final currentStreak = 50;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 500);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 051: verifies streak of 51 days earns Cây Tùng Bách', () {
      final currentStreak = 51;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 510);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 052: verifies streak of 52 days earns Cây Tùng Bách', () {
      final currentStreak = 52;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 520);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 053: verifies streak of 53 days earns Cây Tùng Bách', () {
      final currentStreak = 53;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 530);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 054: verifies streak of 54 days earns Cây Tùng Bách', () {
      final currentStreak = 54;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 540);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 055: verifies streak of 55 days earns Cây Tùng Bách', () {
      final currentStreak = 55;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 550);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 056: verifies streak of 56 days earns Cây Tùng Bách', () {
      final currentStreak = 56;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 560);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 057: verifies streak of 57 days earns Cây Tùng Bách', () {
      final currentStreak = 57;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 570);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 058: verifies streak of 58 days earns Cây Tùng Bách', () {
      final currentStreak = 58;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 580);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 059: verifies streak of 59 days earns Cây Tùng Bách', () {
      final currentStreak = 59;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 590);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 060: verifies streak of 60 days earns Cây Tùng Bách', () {
      final currentStreak = 60;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 600);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 061: verifies streak of 61 days earns Cây Tùng Bách', () {
      final currentStreak = 61;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 610);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 062: verifies streak of 62 days earns Cây Tùng Bách', () {
      final currentStreak = 62;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 620);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 063: verifies streak of 63 days earns Cây Tùng Bách', () {
      final currentStreak = 63;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 630);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 064: verifies streak of 64 days earns Cây Tùng Bách', () {
      final currentStreak = 64;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 640);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 065: verifies streak of 65 days earns Cây Tùng Bách', () {
      final currentStreak = 65;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 650);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 066: verifies streak of 66 days earns Cây Tùng Bách', () {
      final currentStreak = 66;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 660);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 067: verifies streak of 67 days earns Cây Tùng Bách', () {
      final currentStreak = 67;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 670);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 068: verifies streak of 68 days earns Cây Tùng Bách', () {
      final currentStreak = 68;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 680);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 069: verifies streak of 69 days earns Cây Tùng Bách', () {
      final currentStreak = 69;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 690);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 070: verifies streak of 70 days earns Cây Tùng Bách', () {
      final currentStreak = 70;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 700);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 071: verifies streak of 71 days earns Cây Tùng Bách', () {
      final currentStreak = 71;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 710);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 072: verifies streak of 72 days earns Cây Tùng Bách', () {
      final currentStreak = 72;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 720);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 073: verifies streak of 73 days earns Cây Tùng Bách', () {
      final currentStreak = 73;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 730);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 074: verifies streak of 74 days earns Cây Tùng Bách', () {
      final currentStreak = 74;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 740);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 075: verifies streak of 75 days earns Cây Tùng Bách', () {
      final currentStreak = 75;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 750);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 076: verifies streak of 76 days earns Cây Tùng Bách', () {
      final currentStreak = 76;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 760);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 077: verifies streak of 77 days earns Cây Tùng Bách', () {
      final currentStreak = 77;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 770);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 078: verifies streak of 78 days earns Cây Tùng Bách', () {
      final currentStreak = 78;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 780);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 079: verifies streak of 79 days earns Cây Tùng Bách', () {
      final currentStreak = 79;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 790);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 080: verifies streak of 80 days earns Cây Tùng Bách', () {
      final currentStreak = 80;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 800);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 081: verifies streak of 81 days earns Cây Tùng Bách', () {
      final currentStreak = 81;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 810);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 082: verifies streak of 82 days earns Cây Tùng Bách', () {
      final currentStreak = 82;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 820);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 083: verifies streak of 83 days earns Cây Tùng Bách', () {
      final currentStreak = 83;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 830);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 084: verifies streak of 84 days earns Cây Tùng Bách', () {
      final currentStreak = 84;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 840);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 085: verifies streak of 85 days earns Cây Tùng Bách', () {
      final currentStreak = 85;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 850);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 086: verifies streak of 86 days earns Cây Tùng Bách', () {
      final currentStreak = 86;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 860);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 087: verifies streak of 87 days earns Cây Tùng Bách', () {
      final currentStreak = 87;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 870);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 088: verifies streak of 88 days earns Cây Tùng Bách', () {
      final currentStreak = 88;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 880);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 089: verifies streak of 89 days earns Cây Tùng Bách', () {
      final currentStreak = 89;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 890);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 090: verifies streak of 90 days earns Cây Tùng Bách', () {
      final currentStreak = 90;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 900);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 091: verifies streak of 91 days earns Cây Tùng Bách', () {
      final currentStreak = 91;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 910);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 092: verifies streak of 92 days earns Cây Tùng Bách', () {
      final currentStreak = 92;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 920);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 093: verifies streak of 93 days earns Cây Tùng Bách', () {
      final currentStreak = 93;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 930);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 094: verifies streak of 94 days earns Cây Tùng Bách', () {
      final currentStreak = 94;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 940);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 095: verifies streak of 95 days earns Cây Tùng Bách', () {
      final currentStreak = 95;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 950);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 096: verifies streak of 96 days earns Cây Tùng Bách', () {
      final currentStreak = 96;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 960);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 097: verifies streak of 97 days earns Cây Tùng Bách', () {
      final currentStreak = 97;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 970);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 098: verifies streak of 98 days earns Cây Tùng Bách', () {
      final currentStreak = 98;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 980);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 099: verifies streak of 99 days earns Cây Tùng Bách', () {
      final currentStreak = 99;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 990);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

    test('Evaluation case 100: verifies streak of 100 days earns Cây Tùng Bách', () {
      final currentStreak = 100;
      final accumulatedPoints = currentStreak * 10;
      expect(accumulatedPoints, 1000);
      final String badge;
      if (currentStreak >= 14) {
        badge = 'Cây Tùng Bách';
      } else if (currentStreak >= 7) {
        badge = 'Bông Sen Vàng';
      } else {
        badge = 'Bông Sen Xanh';
      }
      expect(badge, 'Cây Tùng Bách');
      expect(currentStreak >= 0, isTrue);
    });

  });
}
