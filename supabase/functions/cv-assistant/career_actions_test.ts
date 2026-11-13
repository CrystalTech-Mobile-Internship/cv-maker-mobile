import { actions } from "./actions.ts";

function assertEquals(actual: unknown, expected: unknown, message = "") {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${message}\nexpected ${e}\nactual   ${a}`);
}

const tailorInput = actions.tailor_cv.validate({
  language: "vi",
  summary: "Sinh viên CNTT",
  skills: ["Git", "Flutter"],
  experiences: [{ id: "e1", title: "Intern", bullets: ["Làm app"] }],
  jobDescription:
    "Tuyển Flutter developer biết Docker, CI/CD và làm việc nhóm.",
});

Deno.test("tailor_cv keeps only original skills in the order", () => {
  const result = actions.tailor_cv.parse(
    JSON.stringify({
      summary: "Tóm tắt mới",
      skillsOrder: ["flutter", "Kubernetes", "Git"],
      missingSkills: ["Docker", "git"],
      experiences: [
        { id: "e1", bullets: ["- Phát triển app"] },
        { id: "invented", bullets: ["x"] },
      ],
    }),
    tailorInput,
  )!;
  assertEquals(result.skillsOrder, ["Flutter", "Git"]);
  assertEquals(result.missingSkills, ["Docker"]);
  assertEquals(result.experiences, [{ id: "e1", bullets: ["Phát triển app"] }]);
});

Deno.test("tailor_cv requires a real job description", () => {
  assertEquals(
    actions.tailor_cv.validate({ summary: "x", jobDescription: "ngắn" }),
    null,
  );
});

Deno.test("interview_questions parses and caps questions", () => {
  const input = actions.interview_questions.validate({
    cv: "Thực tập sinh Flutter, làm app CV với Riverpod và Supabase.",
  });
  const result = actions.interview_questions.parse(
    JSON.stringify({
      questions: Array.from({ length: 10 }, (_, i) => ({
        question: `Câu ${i + 1}?`,
        focus: "f",
      })).concat([{ question: "" } as never]),
    }),
    input,
  )!;
  assertEquals((result.questions as unknown[]).length, 8);
});

Deno.test("answer_feedback clamps the score", () => {
  const input = actions.answer_feedback.validate({
    question: "Bạn dùng state management nào?",
    answer: "Em dùng Riverpod để tách logic khỏi widget.",
  });
  const result = actions.answer_feedback.parse(
    JSON.stringify({ score: 14, sampleAnswer: "Mẫu", strengths: ["a"] }),
    input,
  )!;
  assertEquals(result.score, 10);
  assertEquals(
    actions.answer_feedback.validate({ question: "Q?", answer: "ngắn" }),
    null,
  );
});
