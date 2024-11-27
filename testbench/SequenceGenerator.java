/**
 * Prova Finale di Reti Logiche
 * Anno Accademico 2023-2024
 * Politecnico di Milano
 * Filippo Raimondi
 * 10809051
 * Generatore di Sequenze
 */

import java.util.ArrayList;
import java.util.concurrent.ThreadLocalRandom;

public class SequenceGenerator {

    private final static int K = 24;

    private final static int TEST = 1;

    private static void createStandardSequence(ArrayList<Integer> initialSequence) {
        int w = 0;
        int c = 0;
        for (int i = 0; i < K * 2; i += 2) {
            if (i == 0) {
                w = ThreadLocalRandom.current().nextInt(1, 256);
            } else {
                if (ThreadLocalRandom.current().nextInt(0, 3) == 0)
                    w = 0;
                else
                    w = ThreadLocalRandom.current().nextInt(1, 256);
            }
            initialSequence.add(i, w);
            initialSequence.add(i + 1, c);
        }
    }

    private static void createCredibilityToZeroSequence(ArrayList<Integer> initialSequence) {
        for (int i = 0; i < K * 2; i += 2) {
            if (i == 0) {
                initialSequence.add(i, ThreadLocalRandom.current().nextInt(1, 256));
            } else {
                initialSequence.add(i, 0);
            }
            initialSequence.add(i + 1, 0);
        }
    }

    private static void createOnlyZeroSequence(ArrayList<Integer> initialSequence) {
        for (int i = 0; i < K * 2; i += 2) {
            initialSequence.add(i, 0);
            initialSequence.add(i + 1, 0);
        }
    }

    private static void createNonZeroCredibilitySequence(ArrayList<Integer> initialSequence) {
        for (int i = 0; i < K * 2; i += 2) {
            if (i == 0) {
                initialSequence.add(i, ThreadLocalRandom.current().nextInt(1, 256));
                initialSequence.add(i + 1, ThreadLocalRandom.current().nextInt(0, 256));
            } else {
                if (ThreadLocalRandom.current().nextInt(0, 3) == 0) {
                    initialSequence.add(i, 0);
                    initialSequence.add(i + 1, 0);
                } else {
                    initialSequence.add(i, ThreadLocalRandom.current().nextInt(1, 256));
                    initialSequence.add(i + 1, ThreadLocalRandom.current().nextInt(0, 256));
                }
            }
        }
    }

    private static void createHighFrequencyOfZeroSequence(ArrayList<Integer> initialSequence) {
        int w = 0;
        int c = 0;
        for (int i = 0; i < K * 2; i += 2) {
            if (i == 0) {
                w = ThreadLocalRandom.current().nextInt(1, 256);
            } else {
                if (ThreadLocalRandom.current().nextInt(0, 2) == 0)
                    w = 0;
                else
                    w = ThreadLocalRandom.current().nextInt(1, 256);
            }
            initialSequence.add(i, w);
            initialSequence.add(i + 1, c);
        }
    }

    private static void createAllInitialZeroSequence(ArrayList<Integer> initialSequence) {
        int zeros = K;
        while (zeros == K) {
            zeros = ThreadLocalRandom.current().nextInt(1, K + 1);
        }
        for (int i = 0; i < zeros * 2; i += 2) {
            initialSequence.add(i, 0);
            initialSequence.add(i + 1, 0);
        }
        int zero = ThreadLocalRandom.current().nextInt(zeros * 2 + 1, K * 2);
        for (int j = zeros * 2; j < K * 2; j += 2) {
            if (j == zero) {
                initialSequence.add(j, 0);
                initialSequence.add(j + 1, 0);
            } else {
                initialSequence.add(j, ThreadLocalRandom.current().nextInt(0, 256));
                initialSequence.add(j + 1, 0);
            }
        }
    }

    private static void createSequenceGreaterThanK(ArrayList<Integer> initialSequence) {
        int k = ThreadLocalRandom.current().nextInt(K + 1, K + 4);
        int w = 0;
        int c = 0;
        for (int i = 0; i < k * 2; i += 2) {
            if (i == 0) {
                w = ThreadLocalRandom.current().nextInt(1, 256);
            } else {
                if (ThreadLocalRandom.current().nextInt(0, 3) == 0)
                    w = 0;
                else
                    w = ThreadLocalRandom.current().nextInt(1, 256);
            }
            initialSequence.add(i, w);
            initialSequence.add(i + 1, c);
        }
    }

    private static void createFinalSequence(ArrayList<Integer> initialSequence, ArrayList<Integer> finalSequence) {
        int last_valid_w = 0;
        int credibility = 0;
        for (int i = 0; i < K * 2; i += 2) {
            if (initialSequence.get(i) != 0) {
                last_valid_w = initialSequence.get(i);
                credibility = 31;
            } else {
                if (credibility > 0)
                    credibility--;
            }
            finalSequence.add(i, last_valid_w);
            finalSequence.add(i + 1, credibility);
        }
        for (int j = K * 2; j < initialSequence.size(); j++) {
            finalSequence.add(j, initialSequence.get(j));
        }
    }

    public static void printSequence(ArrayList<Integer> sequence) {
        System.out.print("(");
        for (int i = 0; i < sequence.size(); i++) {
            System.out.print(sequence.get(i));
            if (i != sequence.size() - 1) {
                System.out.print(",");
                System.out.print(" ");
            }
        }
        System.out.print(")");
    }

    public static void main(String[] args) {
        ArrayList<Integer> initialSequence = new ArrayList<>(K * 2);
        ArrayList<Integer> finalSequence = new ArrayList<>(K * 2);

        switch (TEST) {
            case 1:
                createStandardSequence(initialSequence);
                break;
            case 2:
                createCredibilityToZeroSequence(initialSequence);
                break;
            case 3:
                createOnlyZeroSequence(initialSequence);
                break;
            case 4:
                createNonZeroCredibilitySequence(initialSequence);
                break;
            case 5:
                createHighFrequencyOfZeroSequence(initialSequence);
                break;
            case 6:
                createAllInitialZeroSequence(initialSequence);
                break;
            case 7:
                createSequenceGreaterThanK(initialSequence);
                break;
            default:
                break;
        }

        createFinalSequence(initialSequence, finalSequence);

        System.out.print("Initial Sequence: ");
        printSequence(initialSequence);

        System.out.println();

        System.out.print("Final Sequence: ");
        printSequence(finalSequence);
    }

}