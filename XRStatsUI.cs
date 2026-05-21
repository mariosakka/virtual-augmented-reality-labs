using TMPro;
using UnityEngine;

public class XRStatsUI : MonoBehaviour
{
    public Transform xrOrigin;
    public TextMeshProUGUI teleportsText;
    public TextMeshProUGUI stepsText;

    private Vector3 lastPosition;
    private int teleports = 0;
    private int steps = 0;

    void Start()
    {
        lastPosition = xrOrigin.position;
        UpdateUI();
    }

    void Update()
    {
        Vector3 oldPos = new Vector3(lastPosition.x, 0f, lastPosition.z);
        Vector3 newPos = new Vector3(xrOrigin.position.x, 0f, xrOrigin.position.z);

        float distance = Vector3.Distance(oldPos, newPos);

        if (distance > 1.5f)
        {
            teleports++;
        }
        else if (distance > 0.1f)
        {
            steps++;
        }

        lastPosition = xrOrigin.position;
        UpdateUI();
    }

    void UpdateUI()
    {
        teleportsText.text = "Teleports: " + teleports;
        stepsText.text = "Steps: " + steps;
    }

    public void ResetStats()
    {
        teleports = 0;
        steps = 0;
        lastPosition = xrOrigin.position;
        UpdateUI();
    }
}
