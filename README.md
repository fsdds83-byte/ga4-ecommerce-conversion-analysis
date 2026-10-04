# GA4 Ecommerce Conversion Analysis

GA4 电商转化分析项目，基于 BigQuery Public Dataset，使用 SQL 完成数据质量检查、经营指标、用户漏斗、商品表现、客户价值与渠道分析，并使用 Power BI 构建可视化 Dashboard。

在基础分析框架之上，进一步围绕 View → Add to Cart 转化进行自主下钻，分析设备、渠道与商品之间的差异，并定位 Organic Search 在商品维度上的转化缺口。

## Key Findings

- 数据规模：约 429 万条事件、27 万匿名用户
- View → Add to Cart 转化率：20.48%
- 204 个可比商品中，88.73% 在 Organic Search 下的加购率低于同商品其他渠道
- Organic Search 加权 View → Cart：23.76%
- 同商品其他渠道匹配基准：25.75%
- Benchmark Cart Gap：约 6,217 个加购用户

## Dashboard

Power BI Dashboard 共 5 页：

### 1. Executive Overview
![Executive Overview](dashboard/01_executive_overview.png)

### 2. Customer & Funnel Analysis
![Customer & Funnel Analysis](dashboard/02_customer_funnel_analysis.png)

### 3. Product Performance
![Product Performance](dashboard/03_product_performance.png)

### 4. Acquisition & Audience
![Acquisition & Audience](dashboard/04_acquisition_audience.png)

### 5. Organic Search Diagnosis
![Organic Search Diagnosis](dashboard/05_organic_search_diagnosis.png)

## Tech Stack

- BigQuery SQL
- GA4 event-level data
- Power BI
- DAX
- Funnel Analysis
- Product & Channel Diagnosis

## Project Structure

```text
sql/
dashboard/
README.md
